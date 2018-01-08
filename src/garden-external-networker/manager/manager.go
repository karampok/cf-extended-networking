package manager

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"code.cloudfoundry.org/garden"
	"github.com/containernetworking/cni/pkg/types"
	"github.com/containernetworking/cni/pkg/types/020"
)

//go:generate counterfeiter -o ../fakes/cniController.go --fake-name CNIController . cniController
type cniController interface {
	Up(namespacePath, handle string, metadata map[string]interface{}, legacyNetConf map[string]interface{}) (types.Result, error)
	Down(namespacePath, handle string) error
}

//go:generate counterfeiter -o ../fakes/mounter.go --fake-name Mounter . mounter
type mounter interface {
	IdempotentlyMount(source, target string) error
	RemoveMount(target string) error
}

//go:generate counterfeiter -o ../fakes/portAllocator.go --fake-name PortAllocator . portAllocator
type portAllocator interface {
	AllocatePort(handle string, port int) (int, error)
	ReleaseAllPorts(handle string) error
}
type PortMapEntry struct {
	HostPort      uint32 `json:"hostPort"`
	ContainerPort uint32 `json:"containerPort"`
	Protocol      string `json:"protocol"`
	HostIP        string `json:"hostIP,omitempty"`
}

type IPMasqEntry struct {
	External    string `json:"external,omitempty"`
	Destination string `json:"destination,omitempty"`
	Protocol    string `json:"protocol"`
	Description string `json:"description,omitempty"`
}

type Manager struct {
	Logger        io.Writer
	CNIController cniController
	Mounter       mounter
	BindMountRoot string
	PortAllocator portAllocator
}

type UpInputs struct {
	Pid        int
	Properties map[string]interface{}
	NetOut     []garden.NetOutRule `json:"netout_rules"`
	NetIn      []garden.NetIn      `json:"netin"`
}
type UpOutputs struct {
	Properties struct {
		ContainerIP      string `json:"garden.network.container-ip"`
		DeprecatedHostIP string `json:"garden.network.host-ip"`
		MappedPorts      string `json:"garden.network.mapped-ports"`
	} `json:"properties"`
	DNSServers []string `json:"dns_servers,omitempty"`
}

func (m *Manager) Up(containerHandle string, inputs UpInputs) (*UpOutputs, error) {
	if inputs.Pid == 0 {
		return nil, errors.New("up missing pid")
	}
	if containerHandle == "" {
		return nil, errors.New("up missing container handle")
	}

	procNsPath := fmt.Sprintf("/proc/%d/ns/net", inputs.Pid)
	bindMountPath := filepath.Join(m.BindMountRoot, containerHandle)

	err := m.Mounter.IdempotentlyMount(procNsPath, bindMountPath)
	if err != nil {
		return nil, fmt.Errorf("failed mounting %s to %s: %s", procNsPath, bindMountPath, err)
	}

	mappedPorts := []garden.PortMapping{}
	mPorts := []PortMapEntry{}
	for i := range inputs.NetIn {
		if inputs.NetIn[i].HostPort == 0 {
			hostPort, err := m.PortAllocator.AllocatePort(containerHandle, int(inputs.NetIn[i].HostPort))
			if err != nil {
				return nil, fmt.Errorf("allocating port: %s", err)
			}
			inputs.NetIn[i].HostPort = uint32(hostPort)
		}

		mappedPorts = append(mappedPorts, garden.PortMapping{
			HostPort:      inputs.NetIn[i].HostPort,
			ContainerPort: inputs.NetIn[i].ContainerPort,
		})

		mPorts = append(mPorts, PortMapEntry{
			HostPort:      inputs.NetIn[i].HostPort,
			ContainerPort: inputs.NetIn[i].ContainerPort,
			Protocol:      "tcp",
		})

	}

	cmd := exec.Command("sh", "-c", "ip route get 1.1.1.1 | grep -oP 'src \\K\\S+'")
	ip, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("Cannot find external IP: %s", err)
	}

	masqMap := make(map[string]string)
	file, err := os.Open("/var/vcap/data/cni-configs/masqrules.config")
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		v := strings.Split(scanner.Text(), "=")
		masqMap[v[0]] = v[1] //TODO. insecure stuff
	}

	srcPort := "5000:5100"
	if spaceID, ok := inputs.Properties["space_id"]; ok {
		if v, ok := masqMap[spaceID.(string)]; ok {
			srcPort = v
		}
	}
	ipMasqs := []IPMasqEntry{IPMasqEntry{
		External:    fmt.Sprintf("%s:%s", bytes.Trim(ip, "\n"), srcPort),
		Destination: "0.0.0.0/0",
		Protocol:    "tcp",
		Description: "default-rule",
	},
		IPMasqEntry{
			External:    fmt.Sprintf("%s:%s", bytes.Trim(ip, "\n"), srcPort),
			Destination: "8.8.8.8/32",
			Protocol:    "udp",
			Description: "default-rule",
		},
	}

	result, err := m.CNIController.Up(
		bindMountPath,
		containerHandle,
		inputs.Properties,
		map[string]interface{}{
			"portMappings": mPorts,
			"masqEntries":  ipMasqs,
			"metadata":     inputs.Properties,
			"netOutRules":  inputs.NetOut,
		},
	)
	if err != nil {
		return nil, fmt.Errorf("cni up failed: %s", err)
	}

	if result == nil {
		return nil, errors.New("cni up failed: no ip allocated")
	}

	result020, err := result.GetAsVersion("0.2.0")
	if err != nil {
		return nil, fmt.Errorf("cni plugin result version incompatible: %s", err) // not tested
	}

	containerIP := result020.(*types020.Result).IP4.IP.IP

	outputs := UpOutputs{}
	outputs.Properties.MappedPorts = toJson(mappedPorts)
	outputs.Properties.ContainerIP = containerIP.String()
	outputs.Properties.DeprecatedHostIP = "255.255.255.255"
	outputs.DNSServers = result020.(*types020.Result).DNS.Nameservers
	return &outputs, nil
}

func (m *Manager) Down(containerHandle string) error {
	if containerHandle == "" {
		return errors.New("down missing container handle")
	}

	bindMountPath := filepath.Join(m.BindMountRoot, containerHandle)

	err := m.CNIController.Down(bindMountPath, containerHandle)
	if err != nil {
		return fmt.Errorf("cni down: %s", err)
	}

	if err = m.Mounter.RemoveMount(bindMountPath); err != nil {
		fmt.Fprintf(m.Logger, "removing bind mount %s: %s\n", bindMountPath, err)
	}

	if err = m.PortAllocator.ReleaseAllPorts(containerHandle); err != nil {
		fmt.Fprintf(m.Logger, "releasing ports: %s\n", err)
	}

	return nil
}

func toJson(mappedPorts []garden.PortMapping) string {
	bytes, err := json.Marshal(mappedPorts)
	if err != nil {
		panic(err) // untested, should never happen
	}

	return string(bytes)
}

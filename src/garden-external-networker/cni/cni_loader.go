package cni

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/containernetworking/cni/libcni"
)

type CNILoader struct {
	PluginDir string
	ConfigDir string
}

func (l *CNILoader) GetCNIConfig() *libcni.CNIConfig {
	return &libcni.CNIConfig{Path: []string{l.PluginDir}}
}

func (l *CNILoader) GetNetworkConfigs() ([]*libcni.NetworkConfig, error) {
	networkConfigs := []*libcni.NetworkConfig{}
	err := filepath.Walk(l.ConfigDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		if !strings.HasSuffix(path, ".conf") {
			return nil
		}

		conf, err := libcni.ConfFromFile(path)
		if err != nil {
			return fmt.Errorf("unable to load config from %s: %s", path, err)
		}

		networkConfigs = append(networkConfigs, conf)
		return nil
	})

	if err != nil {
		return networkConfigs, fmt.Errorf("error loading config: %s", err)
	}

	return networkConfigs, nil
}

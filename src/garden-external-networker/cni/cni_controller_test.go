package cni_test

import (
	"fmt"
	"garden-external-networker/cni"
	"garden-external-networker/fakes"

	"github.com/containernetworking/cni/libcni"
	"github.com/containernetworking/cni/pkg/types"
	"github.com/containernetworking/cni/pkg/types/020"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CniController", func() {
	var (
		controller     cni.CNIController
		fakeCNILibrary *fakes.CNILibrary
		expectedResult *types020.Result
		testConfig     *libcni.NetworkConfig
	)

	BeforeEach(func() {
		fakeCNILibrary = &fakes.CNILibrary{}

		testConfig = &libcni.NetworkConfig{
			Network: &types.NetConf{
				CNIVersion: "some-version",
				Type:       "some-plugin",
			},
			Bytes: []byte(`{
					"cniVersion":"some-version",
					"type": "some-plugin"
				}`),
		}
		expectedResult = &types020.Result{}
		fakeCNILibrary.AddNetworkReturns(expectedResult, nil)
		fakeCNILibrary.DelNetworkReturns(nil)

		controller = cni.CNIController{
			CNIConfig: fakeCNILibrary,
			NetworkConfigs: []*libcni.NetworkConfig{
				testConfig, testConfig,
			},
		}
	})

	Describe("Up", func() {
		var (
			expectedNetConfBytes string
			metadata             map[string]interface{}
			legacyNetConf        map[string]interface{}
		)
		BeforeEach(func() {
			expectedNetConfBytes = `{
				"cniVersion":"some-version",
				"type":"some-plugin",
				"runtimeConfig": {
					"some-other": "value",
					"another": "something"
				},
				"metadata": {
					"some":"properties"
				}
			}`
			metadata = map[string]interface{}{
				"some": "properties",
			}
			legacyNetConf = map[string]interface{}{
				"some-other": "value",
				"another":    "something",
			}
		})

		It("returns the result from the CNI AddNetwork call", func() {
			result, err := controller.Up("/some/namespace/path", "some-handle", metadata, legacyNetConf)
			Expect(err).NotTo(HaveOccurred())
			Expect(result).To(BeIdenticalTo(expectedResult))

			Expect(fakeCNILibrary.AddNetworkCallCount()).To(Equal(2))
			netc, runc := fakeCNILibrary.AddNetworkArgsForCall(0)
			Expect(runc.ContainerID).To(Equal("some-handle"))
			Expect(netc.Network.Type).To(Equal("some-plugin"))
			Expect(netc.Bytes).To(MatchJSON(expectedNetConfBytes))
		})

		Context("when injecting the metadata fails", func() {
			It("return a meaningful error", func() {
				controller.NetworkConfigs[0].Bytes = []byte(`not valid json`)

				_, err := controller.Up("/some/namespace/path", "some-handle", metadata, legacyNetConf)
				Expect(err).To(MatchError(HavePrefix("adding extra data to CNI config: unmarshal")))
			})
		})

		Context("when the legacyNetConf is nil", func() {
			BeforeEach(func() {
				expectedNetConfBytes = `{
				"cniVersion":"some-version",
				"type":"some-plugin",
				"metadata": {
					"some":"properties"
				}
			}`
			})
			It("adds an empty runtimeConfig", func() {
				_, err := controller.Up("/some/namespace/path", "some-handle", metadata, nil)
				Expect(err).NotTo(HaveOccurred())

				Expect(fakeCNILibrary.AddNetworkCallCount()).To(Equal(2))
				netc, _ := fakeCNILibrary.AddNetworkArgsForCall(0)
				Expect(netc.Bytes).To(MatchJSON(expectedNetConfBytes))
			})
		})

		Context("when the AddNetwork returns an error", func() {
			It("return a meaningful error", func() {
				fakeCNILibrary.AddNetworkReturns(nil, fmt.Errorf("patato"))

				_, err := controller.Up("/some/namespace/path", "some-handle", metadata, legacyNetConf)
				Expect(err).To(MatchError("add network failed: patato"))
			})
		})
	})

	Describe("Down", func() {
		It("returns no error from the CNI DeleteNetwork call", func() {
			err := controller.Down("/some/namespace/path", "some-handle")
			Expect(err).NotTo(HaveOccurred())

			Expect(fakeCNILibrary.DelNetworkCallCount()).To(Equal(2))
			netc, runc := fakeCNILibrary.DelNetworkArgsForCall(0)
			Expect(runc.ContainerID).To(Equal("some-handle"))
			Expect(netc.Network.Type).To(Equal("some-plugin"))
		})

		Context("when the DelNetwork returns an error", func() {
			It("return a meaningful error", func() {
				fakeCNILibrary.DelNetworkReturns(fmt.Errorf("patato"))

				err := controller.Down("/some/namespace/path", "some-handle")
				Expect(err).To(MatchError("del network failed: patato"))
			})
		})
	})
})

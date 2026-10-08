package test

import (
	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
)

type BlueprintOutputs struct {
	ArcConnectedClusterName   string `output:"arc_connected_cluster_name"`
	VmUsername                string `output:"vm_username"`
	VmNames                   any    `output:"vm_names"`
	AioCertManagerExtensionId string `output:"aio_cert_manager_extension_id"`
}

func (BlueprintOutputs) GetRequiredOutputKeys() []string {
	return testutil.GetOutputKeysFromStruct(BlueprintOutputs{})
}

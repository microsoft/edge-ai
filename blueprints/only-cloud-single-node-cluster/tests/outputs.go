package test

import (
	testutil "github.com/microsoft/edge-ai/src/900-tools-utilities/904-test-utilities"
)

type BlueprintOutputs struct {
	VmUsername                string `output:"vm_username"`
	VmNames                   any    `output:"vm_names"`
	AksName                   string `output:"aks_name"`
	AcrName                   string `output:"acr_name"`
	KeyVaultName              string `output:"key_vault_name"`
	SseIdentityName           string `output:"sse_identity_name"`
	AioIdentityName           string `output:"aio_identity_name"`
	DeployIdentityName        string `output:"deploy_identity_name"`
	ArcOnboardingIdentityName string `output:"arc_onboarding_identity_name"`
}

func (BlueprintOutputs) GetRequiredOutputKeys() []string {
	return testutil.GetOutputKeysFromStruct(BlueprintOutputs{})
}

# Changelog

## [3.0.0](https://github.com/microsoft/edge-ai/compare/v2.8.0...v3.0.0) (2026-05-14)


### ⚠ BREAKING CHANGES

* **terraform:** upgrade required_version floor from 1.9.8 to 1.12.0 ([#487](https://github.com/microsoft/edge-ai/issues/487))

### Features

* **500-application:** add 514-wasm-msg-to-dss WASM map operator with DSS enrichment pattern ([#356](https://github.com/microsoft/edge-ai/issues/356)) ([db882a5](https://github.com/microsoft/edge-ai/commit/db882a572928e47df9c7a8d0bbf952d1dfb0c7fe))
* add tags support to all blueprints and remove deprecated federated identity reference ([#483](https://github.com/microsoft/edge-ai/issues/483)) ([c9c8967](https://github.com/microsoft/edge-ai/commit/c9c8967dd4c7ad5e9f6a19e80aeb6eea291b9ff2))
* add unit tests for application services (Rust + Python) ([#372](https://github.com/microsoft/edge-ai/issues/372)) ([220ab28](https://github.com/microsoft/edge-ai/commit/220ab2895d503fe5fd1d2221a612a37e4756abea))
* **avro-to-json:** add unit tests for wire format config parsing ([#368](https://github.com/microsoft/edge-ai/issues/368)) ([65bc924](https://github.com/microsoft/edge-ai/commit/65bc9247b76bb881a7c4663ba0d368b30623a03c))
* **build:** add multi-language fuzzing infra (CFLite + Codecov flags) ([#453](https://github.com/microsoft/edge-ai/issues/453)) ([7407230](https://github.com/microsoft/edge-ai/commit/7407230cb18238ce143cfbf7531032160bf9651e))
* **ci:** enforce rust crate registration in codecov coverage ([#155](https://github.com/microsoft/edge-ai/issues/155)) ([#449](https://github.com/microsoft/edge-ai/issues/449)) ([9b33d69](https://github.com/microsoft/edge-ai/commit/9b33d69fdf39cf4c77eb95453048977b30b46462))
* **docs:** migrate from Docsify to Docusaurus ([#399](https://github.com/microsoft/edge-ai/issues/399)) ([ca06002](https://github.com/microsoft/edge-ai/commit/ca060022c4a2a81dda97d488bbc56e9baa0d1c91))
* **iot-ops:** upgrade AIO 2604 release (1.3.70), harden schema-registry RBAC ([#471](https://github.com/microsoft/edge-ai/issues/471)) ([e772b74](https://github.com/microsoft/edge-ai/commit/e772b74a968efdfa76854383886ca61fa9eb273f))
* **release-please:** implement PAI 1+6 jobs DAG with binary integrity and tag signature verification ([#501](https://github.com/microsoft/edge-ai/issues/501)) ([dc58f10](https://github.com/microsoft/edge-ai/commit/dc58f10995f1d4662b3d4fd4315a977828ca6e17))
* **terraform:** upgrade required_version floor from 1.9.8 to 1.12.0 ([#487](https://github.com/microsoft/edge-ai/issues/487)) ([49229da](https://github.com/microsoft/edge-ai/commit/49229daf1df9bdac9049b00b79af3f6ef8283a86))


### Bug Fixes

* **ai-edge-inference:** bump notify 7 to 8 (partial RUSTSEC-2024-0384) ([#469](https://github.com/microsoft/edge-ai/issues/469)) ([f548586](https://github.com/microsoft/edge-ai/commit/f548586af63f42f138541a4bdb0531b8c524f56c))
* **build:** pin all dependencies for OSSF Scorecard ([#402](https://github.com/microsoft/edge-ai/issues/402)) ([79e6971](https://github.com/microsoft/edge-ai/commit/79e6971628287bce6439a6459445ab715ba17a87))
* **build:** resolve all 4 main branch CI lint failures ([#365](https://github.com/microsoft/edge-ai/issues/365)) ([f90ad6f](https://github.com/microsoft/edge-ai/commit/f90ad6f2815ba05d90fad1e632d812385c9ba972))
* **build:** use valid 'rust' cataloger tag for Syft v1.42.3+ ([#423](https://github.com/microsoft/edge-ai/issues/423)) ([f168e56](https://github.com/microsoft/edge-ai/commit/f168e56a9477fb8f05a73a4fdd8355af842e8982))
* **deps:** bump openssl to 0.10.79 across remaining Rust services ([#480](https://github.com/microsoft/edge-ai/issues/480)) ([14e6f16](https://github.com/microsoft/edge-ai/commit/14e6f16c767e907d9ef313756d1c557083805696))
* **docker:** replace awk with cut for hash verification in Dockerfiles and templates ([#493](https://github.com/microsoft/edge-ai/issues/493)) ([80e97fd](https://github.com/microsoft/edge-ai/commit/80e97fd177ce4210d4b09cffbe438ecaf70c1c3e))
* **docs:** remove ignoreDeprecations in tsconfig.json ([#488](https://github.com/microsoft/edge-ai/issues/488)) ([1b4af53](https://github.com/microsoft/edge-ai/commit/1b4af53d9a35d9f9c14ec152041d98eb65fd5d9f))
* **docs:** silence TS5101 baseUrl deprecation in docusaurus tsconfig ([#475](https://github.com/microsoft/edge-ai/issues/475)) ([ff9d53f](https://github.com/microsoft/edge-ai/commit/ff9d53f86da41a979b714f9918f3867339b3a348))
* **release-please:** use client-id instead of deprecated app-id ([#491](https://github.com/microsoft/edge-ai/issues/491)) ([aff623c](https://github.com/microsoft/edge-ai/commit/aff623c0e4f7e1505aeb63e6ce4b98bcf601f22a))
* **scripts:** align Grype writer/reader naming so security gate fails closed ([#362](https://github.com/microsoft/edge-ai/issues/362)) ([#411](https://github.com/microsoft/edge-ai/issues/411)) ([64b3db3](https://github.com/microsoft/edge-ai/commit/64b3db30c81e2cc01ea775946fdd5e59d0844a26))
* update stale hashes for checkov and requests in requirements.txt ([#516](https://github.com/microsoft/edge-ai/issues/516)) ([fa3c57f](https://github.com/microsoft/edge-ai/commit/fa3c57f88745ae2b81537a4e8b1423f15a2fb0c9))
* **workflows:** harden CI workflows to fail-fast on lint, security, and doc-gen errors ([#393](https://github.com/microsoft/edge-ai/issues/393)) ([4669835](https://github.com/microsoft/edge-ai/commit/4669835bc57f7862b99c61388472754045a7b8e5))


### Documentation

* add OpenSSF Scorecard badge to README ([#371](https://github.com/microsoft/edge-ai/issues/371)) ([917851b](https://github.com/microsoft/edge-ai/commit/917851bc5a3db1136490f5d61d126c7f872ab3b1))
* **adrs:** document .terraform.lock.hcl exclusion rationale ([#505](https://github.com/microsoft/edge-ai/issues/505)) ([7c7185b](https://github.com/microsoft/edge-ai/commit/7c7185b341f251cf31cb40d4fb5efa0e232599ea))
* **governance:** add GOVERNANCE.md ([#160](https://github.com/microsoft/edge-ai/issues/160)) ([#503](https://github.com/microsoft/edge-ai/issues/503)) ([76d1cfe](https://github.com/microsoft/edge-ai/commit/76d1cfeaf83ef5f22ec48988a5f88db5e593ab6b))


### Build System

* **deps:** bump Rust and Python deps to clear CI security gates ([#444](https://github.com/microsoft/edge-ai/issues/444)) ([2c05d82](https://github.com/microsoft/edge-ai/commit/2c05d822f60058221b323695e19d04a4b7e046dc))


### Miscellaneous Chores

* **build:** migrate node toolchain to v24 (closes [#458](https://github.com/microsoft/edge-ai/issues/458)) ([#460](https://github.com/microsoft/edge-ai/issues/460)) ([7a7648c](https://github.com/microsoft/edge-ai/commit/7a7648cc1f078b0ba44e95994f30a3de3983d04f))
* **build:** pin pip and CI tool installs for Scorecard ([#464](https://github.com/microsoft/edge-ai/issues/464)) ([1a57e67](https://github.com/microsoft/edge-ai/commit/1a57e670736cd8dd3fecadb3cbc0b87e67f04a9d))
* **deps:** bump github.com/aws/aws-sdk-go-v2/service/lambda from 1.69.0 to 1.88.5 in /blueprints/full-single-node-cluster/tests ([#364](https://github.com/microsoft/edge-ai/issues/364)) ([ca8a5a2](https://github.com/microsoft/edge-ai/commit/ca8a5a247f7dcf8f6205642f372a009d4e06353f))
* **deps:** bump github.com/jackc/pgx/v5 from 5.7.1 to 5.9.0 in /blueprints/full-single-node-cluster/tests ([#397](https://github.com/microsoft/edge-ai/issues/397)) ([57caa75](https://github.com/microsoft/edge-ai/commit/57caa75caf511d49d12fb7c43e545bb06a0a6e7c))
* **deps:** bump github.com/microsoft/kiota-http-go from 1.5.4 to 1.5.5 in /blueprints/full-single-node-cluster/tests ([#485](https://github.com/microsoft/edge-ai/issues/485)) ([f080a5e](https://github.com/microsoft/edge-ai/commit/f080a5e14afc70100a9807788d08c2358d7441b0))
* **deps:** bump github.com/moby/spdystream from 0.5.0 to 0.5.1 in /blueprints/full-single-node-cluster/tests ([#396](https://github.com/microsoft/edge-ai/issues/396)) ([a45f051](https://github.com/microsoft/edge-ai/commit/a45f051e40183af02805d811cb96b978d5fe6e02))
* **deps:** bump openssl from 0.10.78 to 0.10.79 in /src/500-application/507-ai-inference/services/ai-edge-inference ([#477](https://github.com/microsoft/edge-ai/issues/477)) ([8326a97](https://github.com/microsoft/edge-ai/commit/8326a97e10f9b6784d4ba65d53e81f43e7345e1a))
* **deps:** bump openssl from 0.10.78 to 0.10.79 in /src/500-application/507-ai-inference/services/ai-edge-inference-crate ([#476](https://github.com/microsoft/edge-ai/issues/476)) ([8b7536e](https://github.com/microsoft/edge-ai/commit/8b7536e3d3cf2ed711fa8944fa18a707676ff5d5))
* **deps:** bump pytest from 9.0.2 to 9.0.3 in /src/500-application/506-ros2-connector/services ([#394](https://github.com/microsoft/edge-ai/issues/394)) ([14828e7](https://github.com/microsoft/edge-ai/commit/14828e72c91f9d39b28b20e31547947a9199afc8))
* **deps:** bump rand from 0.9.2 to 0.9.4 in /src/500-application/507-ai-inference/services/ai-edge-inference-crate ([#395](https://github.com/microsoft/edge-ai/issues/395)) ([3cac305](https://github.com/microsoft/edge-ai/commit/3cac3050d1f7881b71230bccd6f5954a31224d13))
* **deps:** bump urllib3 from 2.6.3 to 2.7.0 and consolidate dependencies ([#509](https://github.com/microsoft/edge-ai/issues/509)) ([40c1ef6](https://github.com/microsoft/edge-ai/commit/40c1ef6ec773642994dfbcd060598fe60ff83109))
* **deps:** consolidate Dependabot updates into one weekly PR per ecosystem ([#410](https://github.com/microsoft/edge-ai/issues/410)) ([37de2b4](https://github.com/microsoft/edge-ai/commit/37de2b4fd1f84e93dd4f869565cd3e37fee3810f))
* **deps:** remediate Grype/OSSF vulnerabilities ([#451](https://github.com/microsoft/edge-ai/issues/451)) ([#450](https://github.com/microsoft/edge-ai/issues/450)) ([b5d0753](https://github.com/microsoft/edge-ai/commit/b5d07536f4370961d4d168c796b342be425a82e9))
* migrate from GitVersion to release-please ([#446](https://github.com/microsoft/edge-ai/issues/446)) ([d2ced15](https://github.com/microsoft/edge-ai/commit/d2ced159eae1e90cd51e0fbc47a08d8e04bfe4fd))
* **security:** pin remaining unpinned dependencies (OSSF Scorecard) ([#497](https://github.com/microsoft/edge-ai/issues/497)) ([39d385a](https://github.com/microsoft/edge-ai/commit/39d385a0fb633e64e3862960d3a7be20cde27e2a))
* **security:** remediate OSSF Scorecard vulnerability advisories ([#502](https://github.com/microsoft/edge-ai/issues/502)) ([ba570c4](https://github.com/microsoft/edge-ai/commit/ba570c44f8e2c6a5edc542537a78de66e30db8f7))
* vulnerability remediation ([#409](https://github.com/microsoft/edge-ai/issues/409) phases A-G), OSSF hardening, and Docusaurus migration completion ([#408](https://github.com/microsoft/edge-ai/issues/408)) ([b6a3f08](https://github.com/microsoft/edge-ai/commit/b6a3f08ad44c6f7fd37afab3aec606a58339de82))

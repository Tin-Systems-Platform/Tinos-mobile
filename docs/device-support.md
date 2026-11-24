# Device support status

## Summary

There is no confirmed end-to-end supported phone in the repository documentation. The checked-in firmware and packaging work is focused on Samsung devices using Exynos 7884/7885, and the image packaging script is labeled for the SM-A105FN (Galaxy A10). Treat that as a development target, not a release-ready compatibility claim.

| Device / platform | Evidence in this repository | Status |
| --- | --- | --- |
| Exynos 7884/7885 platform | The environment script builds the `edk2-exynos7885` project for AArch64. Its submodule README says the firmware reaches the UEFI shell. | Firmware bring-up reported; exact device coverage and reproducibility are not established here. |
| Samsung SM-A105FN (Galaxy A10) | The image script name and comments use this model; it expects an extracted stock DTB under `stock_boot/`. | Packaging target only. No checked-in evidence establishes a successful Tinos kernel boot. |
| Other Exynos phones | The firmware submodule has notes about porting to other Exynos SoCs and explicitly cautions that porting may fail before reaching the shell. | Experimental; per-device porting and validation required. |
| Other ARM64 phones | No platform firmware, boot image recipe, or test record for other vendors appears in this repository workflow. | Unsupported / unverified. |

## What “support” would require

For a device to be considered supported, record successful results for each layer on that exact model and hardware revision:

- EDK2 starts reliably and exposes the expected UEFI environment.
- The device can locate and start the ARM64 Limine EFI binary.
- Limine reads the configured filesystem and loads the intended kernel artifact.
- The Cosmos kernel reaches its entry point and provides observable output.
- Repeated cold boots work, and the recovery or rollback path is documented.

The repository currently contains assumptions for these steps, not a complete test matrix. Android boot image offsets, page size, DTB handoff, display, input, and other peripherals can vary by model and firmware version. Do not reuse the SM-A105FN image recipe for another device without adapting and validating those details.

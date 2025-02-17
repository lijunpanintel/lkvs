Intel® Trust Domain Extensions (Intel® TDX) is an Intel technology that
expands Virtual Machine Extensions (VMX) with a new type of virtual
machine guest known as a Trust Domain (TD).

A TD is intended to secure the confidentiality of its memory contents,
CPU state, and so on. This patch set aims to develop a TDX compliance
test suite to verify the TDX's consistency to the specification,
preventing potential security risks in the TD environment.

TDX compliance tests contain a series of compliance tests, including
CPUID, CR, MSR. They are designed to verify the security and
functionality of the TD environment, which should work exactly as
designed in the TDX Specification. That will increase the credibility
of Intel TDX.

## Usage
TDX-compliance is designed to work as a kernel module. Before using it,
you need to build it.

### Step 1: Prepare your environment to build kernel modules
Build and install the kernel locally (in TD guest)
Install the source code from distribution

### Step 2: Build tdx-compliance
To build tdx-compliance, follow these steps:

```bash
git clone https://github.com/intel/lkvs.git
cd lkvs/tdx-compliance
make
insmod tdx-compliance
```
### Step 3: Run test cases
To run all kinds of compliance tests, simply enter the following command:

```bash
echo all > /sys/kernel/debug/tdx/tdx-tests
```

To view the results and logs, use this command:
```bash
cat /sys/kernel/debug/tdx/tdx-tests
```
If you want to learn more about tdx-compliance, please refer to the
following resources.

* CPUID

CPUID compliance is part of TDX-compliance tests to make sure whether
the current virtualized TD environment is compliant with the CPUID
instruction, especially for the ones with fixed type, confirming the
expected outputs, and no exceptions occur.

A CPUID compliance test calls the instruction 'cpuid' with leaf or
sub-leaf specified, then check the bits of outputs. All tests are
from the table 2.4(CPUID Virtualization Overview) in Intel® Trust
Domain Extensions (Intel® TDX) Module Architecture Application
Binary Interface (ABI) Reference Specification

Users can execute the compliance test and dump results via the Kernel
interface /sys/kernel/debug/tdx/tdx-tests.

Usage:
Run cpuid compliance tests:
```
echo cpuid > /sys/kernel/debug/tdx/tdx-tests
```

* MSR

The Model Specific Registers (MSR) are special registers in the CPU that
store information related to the processor model. Intel TDX virtualizes
the behavior of the MSRs' read and write.

Usage:
Run MSR compliance tests:
```
each msr > /sys/kernel/debug/tdx/tdx-tests
```

* CR(Control Registers)

CR(Control Register) is a set of registers in the processor used to control
operations. They contain many different control bits that are used to
control how the processor operates. For example, control bits in the CR0
can be used to enable or disable the pagination mechanism, etc.

Usage:
```
echo cr > /sys/kernel/debug/tdx/tdx-tests
```

## Contact:
Sun, Yi (yi.sun@intel.com)


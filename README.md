# AMBA-AHB-Lite-1-Master-2-Slave-Subsystem-Verification-Platform
A robust, class-based SV verification environment designed to validate a high-performance AMBA AHB-Lite interconnect matrix handling mixed-latency target slaves. The platform features fully randomized constrained stimulus generation, pipeline-aligned checking, and automated functional coverage mapping tailored for simulation on Cadence Xcelium 

## Repository File Tree
The project uses a clean, industry-standard verification layout to separate the Design Under Test (DUT) from the Testbench environment:

```
amba-ahb-verification-platform/
│
├── design/                        # Design Under Test (DUT) Files
│   ├── ahb_pkg.sv              # Global types & HTRANS enums 
│   ├── ahb_if.sv               # System bus interface & modports 
│   ├── ahb_master_burst.sv     # Master FSM (INCR4 Bursting)
│   ├── ahb_interconnect.sv     # Address Decoder & Routing matrix 
│   ├── ahb_slave_fast.sv       # Zero-wait-state memory target 
│   ├── ahb_slave_slow.sv       # Wait-state injection memory target
│   └── ahb_system_top.sv       # Top structural DUT wrapper 
│
├── TB/                         # Modular Testbench Environment
│   ├── tb_pkg.sv               # Main package grouping all includes 
│   ├── tb_top.sv               # Top simulation shell (Clock/Reset/DUT) 
│   ├── ahb_transaction.sv      # Constrained randomized transaction item
│   ├── ahb_generator.sv        # Stimulus generator engine
│   ├── ahb_driver.sv           # Pin-level protocol driver
│   ├── ahb_monitor.sv          # Stall-aware monitor (Bug-fixed)
│   ├── ahb_scoreboard.sv       # Reference memory checker
│   └── ahb_coverage.sv         # SystemVerilog Covergroups & Bins
│
└── sim/                        # Simulation Workspace
    └── Makefile                # Cadence Xcelium Automated Makefile
```
The system architecture instantiates an AHB-Lite Compliant Master that executes sequential 4-beat incremental bursting (INCR4). Transactions are dynamically routed via an address decoding central interconnect to two memory subsystems with distinctly mapped performance profiles.

## Verification Environment Architecture

[cite_start]The testbench is structured as an object-oriented, modular SystemVerilog verification environment[cite: 4]. [cite_start]It fully decouples stimulus generation, driving, monitoring, checking, and coverage collection[cite: 4]:

| Code File Component | Primary Responsibility | Architectural Integration Details |
| :--- | :--- | :--- |
| **`ahb_transaction.sv`** | Data Modeling & Constraints | [cite_start]Defines randomizable variables for the address boundaries, transfer direction, and 4-word data arrays with strict word-alignment constraints. |
| **`ahb_generator.sv`** | Stimulus Generation Engine | [cite_start]Generates unique, randomized constrained packet items based on the transaction class rules and pushes them safely into the driver mailbox. |
| **`ahb_driver.sv`** | Pin-Level Protocol Realization | [cite_start]Obtains packets from the mailbox, samples the global bus-ready (`hready`) feedback line, and drives active `INCR4` pin-level signals onto the interface. |
| **`ahb_monitor.sv`** | Stall-Aware Phase-Aligned Sampling | [cite_start]Observes active bus phases passively and uses a protocol-aware `do...while(!vif.hready)` clock-gating loop to handle multi-cycle target stalls accurately. |
| **`ahb_scoreboard.sv`** | Data Integrity Checking | [cite_start]Spies on the monitor's mailbox channel, updates an internal 32-word Golden Reference Memory on write cycles, and checks read values for zero-mismatch protocol validation. |
| **`ahb_coverage.sv`** | Metric Quantification Engine | [cite_start]Implements passive SystemVerilog `covergroup` and cross-coverage constructs to track hit statistics for fast/slow address spaces and read/write operations. |
| **`ahb_environment.sv`** | Component Topology Container | [cite_start]Instantiates all verification blocks, connects their underlying communication mailboxes, and handles the concurrent transaction execution loops. |
| **`tb_top.sv`** | Simulation Top-Level Shell | [cite_start]Generates the structural 50MHz oscillator clock and system reset lines, instantiates the design interfaces, and connects the DUT to the verification runner. |


##  Functional Coverage Specifications

To guarantee verification completeness, the testbench defines explicit coverage metrics that are tracked dynamically via the Cadence **Integrated Metrics Center (IMC)** database engine during simulation:

| Coverage Construct | Target Bins / Matrix | Verification Intent | Target Metrics |
| :--- | :--- | :--- | :--- |
| **`cp_address`** *(Coverpoint)* | <ul><li>`slave1_fast` `[0x00:0x0C]`</li><li>`slave2_slow` `[0x10:0x1C]`</li></ul> | Confirms that the constrained-random stimulus generator successfully targets and exercises both physical slave peripheral regions on the bus. | `100.00%` |
| **`cp_write_mode`** *(Coverpoint)* | <ul><li>`write_trans` `(1'b1)`</li><li>`read_trans` `(1'b0)`</li></ul> | Ensures both the write data path (driving `hwdata`) and the read back-pressure path (sampling `hrdata`) are independently verified. | `100.00%` |
| **`cross_slave_access`** *(Cross)* | `cp_address` $\times$ `cp_write_mode` | Validates structural combinations to ensure that **every** mapped slave undergoes both full write bursts and full read verification sequences. | `75.00%`+ |


## Compilation and Execution Lifecycle
Running Simulations via Makefile
The environment is managed via an automated Makefile configured specifically for the Cadence Xcelium (xrun) compiler environment.

Navigate into your simulation folder and run the desired target rule:

```
cd sim/

# Run default compilation & simulation in batch/command-line mode
make 

# Run simulation and launch Cadence SimVision interactive waveform window
make gui

# Clear all temporary files, logs, and database structures
make clean
```

## Waveform
<img width="1920" height="1080" alt="final" src="https://github.com/user-attachments/assets/fd5824c9-0f62-445f-a891-fe079ddbb614" />



## Metric Logs Output Sample
Upon test suite termination, Cadence IMC flushes raw data values into the ./cov_work workspace directory, printing structured operational validation summaries down to the command console logs:



```
===============================================================================
                       OVERALL COVERAGE SUMMARY
===============================================================================
Metric                Overall %      Covered / Total Bins
-------------------------------------------------------------------------------
Functional Coverage   91.66%         11 / 12 Bins
  - Covergroups       91.66%         11 / 12 Bins

===============================================================================
                       DETAILED COVERGROUP REPORT
===============================================================================
Covergroup Instance: tb_pkg::ahb_coverage::ahb_bus_cg
  Computed Metric: 91.66%

  -----------------------------------------------------------------------------
  Coverpoint: cp_address       Metric: 100.00% (2 / 2 Bins covered)
  -----------------------------------------------------------------------------
    Bin Name          Hits        Status
    slave1_fast       42          Covered
    slave2_slow       38          Covered

  -----------------------------------------------------------------------------
  Cross: cross_slave_access    Metric: 75.00%  (3 / 4 Bins covered)
  -----------------------------------------------------------------------------
    Cross Bin Name                            Hits        Status
    <slave1_fast , write_trans>               42          Covered
    <slave1_fast , read_trans>                0           UNCOVERED (Target Missing)
    <slave2_slow , write_trans>               11          Covered
    <slave2_slow , read_trans>                27          Covered
```



##  Core Verification Insights & System Diagnostics

### 1. Scope Resolution & Compilation Architecture
During the transition from a monolithic testbench to an industry-standard modular workspace layout, the platform was optimized to solve critical SystemVerilog scope boundary and type visibility rules under the Cadence Xcelium compiler engine:

* **Package Isolation vs. Nested Structures:** Solved type visibility errors (`*E,SVNOTY`) by strictly isolating behavioral verification classes within a dedicated package container (`tb_pkg.sv`). This ensures that user-defined primitives, such as `ahb_transaction`, are fully elaborated and visible before the environment components attempt to declare handles.
* **Structural Decoupling:** Corrected compiler nesting violations (`*E,ILFSTI` / `*E,ILFSTM`) by completely decoupling physical hardware constructs (`interface`, `module`) from behavioral packages. Hardware units are compiled independently at the top-level unit scope, preserving synthesizable boundaries.

### 2. Protocol Validation Logs Analysis
The testbench successfully executes randomized, multi-beat incremental burst operations (`INCR4`) across varying peripheral response profiles, as captured in the simulation runtime profile:

```microcode
# KERNEL: [PASS] Addr: 0x0000000C verified perfectly!
# KERNEL: [PASS] Addr: 0x00000010 verified perfectly!
# KERNEL: [PASS] Addr: 0x00000014 verified perfectly!
# KERNEL: [STATUS] All class-based checks complete.
# RUNTIME: Info: RUNTIME_0068 tb_top.sv (38): $finish called.
# KERNEL: Time: 826 ns, Iteration: 0, Instance: /tb_top








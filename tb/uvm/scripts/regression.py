import subprocess
import sys # Gives access to functions and variables used by python interpreter itself

# sys.argv[0] is name of script
# sys.argv[1] is the name of the first argument

# Each subprocess uses its own memory space unlike threads which uses shared memory among themselves

# The 4 tests I wrote
tests = [
    "memory_test",
    "write_read_test",
    "boundary_test",
    "reset_test",
]

# .. go back one level
executable = "../../../obj_dir/Vtb_top"

print("My UVM Regression")

failed = []

for test in tests:
    print(f"\nRunning {test}...")

    result = subprocess.run(
        [executable, f"+UVM_TESTNAME={test}"],
        capture_output=True,
        text=True
    )

    print(result.stdout)

    if result.returncode != 0:
        failed.append(test)
        print(f"{test} FAILED")
        continue

    if "UVM_ERROR :    0" in result.stdout and "UVM_FATAL :    0" in result.stdout:
        print(f"{test} PASSED")
    else:
        failed.append(test)
        print(f"{test} FAILED")

print(" Regression Summary")

if failed:
    print("FAILED TESTS:")
    for test in failed:
        print(f"  - {test}")

    # Kill the script
    sys.exit(1)

print(f"All {len(tests)} tests PASSED.")
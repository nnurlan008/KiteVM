import numpy as np

# Load edge list (1-based index)
edges = np.loadtxt("/users/Nurlan/graphs/com-Friendster/clean/com-Friendster-clean.mtx", dtype=np.uint32)

# Convert to 0-based indexing
edges -= 1

# Confirm shape is (N, 2)
assert edges.shape[1] == 2, "Expected src-dst pairs"

# Save to binary as edgeT_t<uint32_t>: src_id, dst_id
edges.tofile("/users/Nurlan/graphs/com-Friendster/clean/binary/com-Friendster-clean.bin")

print(f"Saved {len(edges)} edges (edgeT_t<uint32_t>) to binary file.")
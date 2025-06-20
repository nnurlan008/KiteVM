import struct, os
import matplotlib.pyplot as plt
from collections import Counter
import numpy as np

file_path = os.path.expanduser("~/rdma_log_graphone_6gb_uk2002_pr.bin")
with open(file_path, "rb") as f:
    data = f.read()

entry_size = 24
valid_size = len(data) - (len(data) % entry_size)
data = data[:valid_size]  # trim any trailing garbage

dictionary_page = {}
page_addresses = []

entries = struct.iter_unpack("QQQ", data)
print("idx,local,remote,op")
for i, (local, remote, rw) in enumerate(entries):
    op = "READ" if rw == 4 else "WRITE"
    
    if op == "READ" and local >> 12 < 1000000:
        page_addresses.append(local >> 12)
        if local in dictionary_page:
            dictionary_page[local] += 1
        else:
            dictionary_page[local] = 1
        # if dictionary_page[local] > 1:
        #     print(f"Duplicate local address {hex(local)} found at index {i}")
    # print(f"{i},{hex(local)},{hex(remote)},{op}")

# indices = list(range(len(page_addresses)))
# plt.figure(figsize=(12, 6))
# plt.scatter(indices, page_addresses, s=1, alpha=0.6)
# plt.xlabel("Page Fault Event Index")
# plt.ylabel("Page Number (local address >> 12)")
# plt.title("Page Faults Over Time")
# plt.grid(True)
# plt.tight_layout()
# plt.savefig("/users/Nurlan/dummy.png", format="png")
# plt.show()


access_counts = Counter(page_addresses)

# Convert to sorted list of access counts
counts = sorted(access_counts.values())

# Compute CDF
cdf_y = np.arange(1, len(counts) + 1) / len(counts)

# Plot CDF
plt.figure(figsize=(8, 4))
plt.plot(counts, cdf_y, marker='.')
plt.xlabel("Number of accesses to a page")
plt.ylabel("Cumulative fraction of pages")
plt.title("CDF of Page Access Frequencies")
plt.grid(True)
plt.tight_layout()
plt.savefig("/users/Nurlan/dummy.png", format="png")
plt.show()



# print(dictionary_page)
print(len(dictionary_page))
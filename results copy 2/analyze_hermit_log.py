import struct, os
import matplotlib.pyplot as plt
from collections import Counter
import numpy as np
import sys

# /*
# * func: 
# * 0: do_anonymous_page; allocate new one which might result in swap out of other pages
# * 1: do_swap_page_profiling: page is in swap cache and 
# * 2: do_swap_page_profiling: page is in remote and fetched on demand
# * 3: hermit_vma_prefetch: page is prefetched to swap cache added to lru and swap_cache
# * 4: hermit_swapin_bypass_swapcache - hermit_issue_read: page is brought on demand
# * 5: hermit_swap_vma_readahead: page is brought on demand
# * 6: shrink_page_list_inner: page is probably sent to swap cache
# */


def just_analyze(option):
    
    with open(file_path, "rb") as f:
        data = f.read()

    entry_size = 32
    valid_size = len(data) - (len(data) % entry_size)
    data = data[:valid_size]  # trim any trailing garbage

    dictionary_page = {}
    page_addresses = []

    entries = struct.iter_unpack("QQQQ", data)
    print("idx,function, address, vma_start, vma_end")
    for i, (function, address, vma_start, vma_end) in enumerate(entries):
        # op = "READ" if rw == 4 else "WRITE"
        if function == option:
            print(function, hex(address), vma_start, vma_end)

        # if op == "READ" and local >> 12 < 1000000:
        #     page_addresses.append(local >> 12)
        #     if local in dictionary_page:
        #         dictionary_page[local] += 1
        #     else:
        #         dictionary_page[local] = 1
            # if dictionary_page[local] > 1:
            #     print(f"Duplicate local address {hex(local)} found at index {i}")
        # print(f"{i},{hex(local)},{hex(remote)},{op}")

def swap_in_out_rate(file_path):
    with open(file_path, "rb") as f:
        data = f.read()

    entry_size = 32
    valid_size = len(data) - (len(data) % entry_size)
    data = data[:valid_size]  # trim any trailing garbage

    dictionary_page = {} 
    # key: virtual address, value: [in, out, in, out, ...]
    page_addresses = []

    entries = struct.iter_unpack("QQQQ", data)
    print("idx,function, address, vma_start, vma_end")
    for i, (function, address, vma_start, vma_end) in enumerate(entries):
        # op = "READ" if rw == 4 else "WRITE"
        if function == 5 or function == 2 or function == 4 or function == 8 or function == 9:
            if address not in dictionary_page:
                dictionary_page[address] = ["in"]
            else:
                dictionary_page[address].append("in")
        elif function == 6:
            if address not in dictionary_page:
                print("Problem with address", hex(address))
                dictionary_page[address] = ["out"]
            else:
                dictionary_page[address].append("out")

    in_events = []

    for address, events in dictionary_page.items():
        in_count = events.count("in")
        out_count = events.count("out")
        if address != 0:
            in_events.append(in_count)

        # if len(events) > 1:
        #     # page_addresses.append((address, in_count, out_count))
        #     print(f"Address: {hex(address)}, {events}")
    in_events.sort()
    print(in_events)

def plot(file_path):
    with open(file_path, "rb") as f:
        data = f.read()

    entry_size = 32
    valid_size = len(data) - (len(data) % entry_size)
    data = data[:valid_size]  # trim any trailing garbage

    dictionary_page = {} 
    # key: virtual address, value: [in, out, in, out, ...]
    page_addresses = []

    entries = struct.iter_unpack("QQQQ", data)
    print("idx,function, address, vma_start, vma_end")
    for i, (function, address, vma_start, vma_end) in enumerate(entries):
        # op = "READ" if rw == 4 else "WRITE"
        if function == 5 or function == 2 or function == 4 or function == 8 or function == 9:
            shifted_address = address >> 12
            if shifted_address > 3e10 and shifted_address < 3.4340e10:
                page_addresses.append(shifted_address)
            
   



    indices = list(range(len(page_addresses)))
    plt.figure(figsize=(12, 6))
    plt.scatter(indices, page_addresses, s=1, alpha=0.6)
    plt.xlabel("Page Fault Event Index")
    plt.ylabel("Page Number (local address >> 12)")
    plt.title("Page Faults Over Time")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("/users/Nurlan/page_fault.png", format="png")
    plt.show()


# access_counts = Counter(page_addresses)

# # Convert to sorted list of access counts
# counts = sorted(access_counts.values())

# # Compute CDF
# cdf_y = np.arange(1, len(counts) + 1) / len(counts)

# # Plot CDF
# plt.figure(figsize=(8, 4))
# plt.plot(counts, cdf_y, marker='.')
# plt.xlabel("Number of accesses to a page")
# plt.ylabel("Cumulative fraction of pages")
# plt.title("CDF of Page Access Frequencies")
# plt.grid(True)
# plt.tight_layout()
# plt.savefig("/users/Nurlan/dummy.png", format="png")
# plt.show()



# print(dictionary_page)
# print(len(dictionary_page))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python analyze_hermit_log.py <file_path> <option>")
        sys.exit(1)

    option = int(sys.argv[2])
    file_path = sys.argv[1] # os.path.expanduser("~/hermit_log.bin")
    # just_analyze(option)
    # swap_in_out_rate(file_path=file_path)
    plot(file_path)
    # You can add more analysis or save results as needed.
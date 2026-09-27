"""Python again, with what bash and Node handed on: where it went, and its size."""
import sys

url, size = sys.argv[1], sys.argv[2]
print(f"live: {url} ({size} bytes)")

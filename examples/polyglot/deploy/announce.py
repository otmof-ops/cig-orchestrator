"""Python again, with what bash and Node handed on: where it went, and its size."""
import sys

where, size = sys.argv[1], sys.argv[2]
print(f"live: {where} ({size} bytes)")

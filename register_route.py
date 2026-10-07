import os
import re

with open("admin-frontend/src/App.tsx", "r") as f:
    content = f.read()

# Add import
if "import AppliedJobs" not in content:
    content = content.replace(
        "import Jobs from './pages/Jobs';",
        "import Jobs from './pages/Jobs';\nimport AppliedJobs from './pages/AppliedJobs';"
    )

# Add route
route_string = '<Route path="/jobs" element={<Jobs />} />'
if 'path="/jobs/applied"' not in content:
    content = content.replace(
        route_string,
        route_string + '\n                <Route path="/jobs/applied" element={<AppliedJobs />} />'
    )

with open("admin-frontend/src/App.tsx", "w") as f:
    f.write(content)

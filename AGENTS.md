Commit early, Commit often.
Write code like it's going to be read by someone who is going to maintain it.
Every Nix module starts with a concise, standalone header that explains its
responsibility without relying on where it is imported.
This repository does not require tests, unless explicitly asked.
The root README provides a project overview and entry points. Keep configuration
details with the relevant module, adding prose only when it explains a necessary
decision or usage requirement.

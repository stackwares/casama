# Computers

Every bot works on a sandboxed Linux computer (Docker, gVisor on Linux hosts, or E2B/Daytona):
shell, files, a browser and, with the desktop image, desktop apps.

- Computers sleep after 10 idle minutes and wake with files and browser logins intact.
- A checkpoint is taken before destructive commands; restore any checkpoint from the app.
- **Live view**: watch the desktop in the app over WebRTC and **take control** at any time; the bot
  pauses and resumes with your note when you hand back.
- Network: computers reach the internet only through an egress proxy that blocks private and
  cloud-metadata addresses. Secrets are injected per host and never shown to the model.

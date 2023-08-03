.PHONY: help
help:  # from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build:  ## Build and start server
	docker compose build

.PHONY: serve
serve:  ## Build and start server
	mkdir --parents data/{ssh_admin,ssh_etc,torch}
	docker compose up

.PHONY: reset-ssh-fingerprint
reset-ssh-fingerprint:
	ssh-keygen -R [localhost]:2000  # This is OK since the server is on the local host.

.PHONY: connect-local-ssh
connect-local-ssh:  reset-ssh-fingerprint  ## Connect to the local server with Xpra
	ssh -o StrictHostKeyChecking=accept-new -p 2000 admin@localhost

.PHONY: connect-local-xpra
connect-local-xpra:  reset-ssh-fingerprint  ## Connect to the local server with Xpra
	xpra attach \
		--ssh 'ssh -o StrictHostKeyChecking=accept-new' \
		--key-shortcut 'Control_R:toggle_keyboard_grab' \
		--notifications=no \
		--speaker=no \
		--system-tray=no \
		--webcam=no \
		--xsettings=no \
		ssh://admin@localhost:2000/42

.PHONY: connect-remote-ssh
connect-remote-ssh:  ## Connect to the local server with Xpra
	ssh -p 2000 "admin@${SL_REMOTE_HOST}"

.PHONY: connect-remote-xpra
connect-remote-xpra:  ## Connect to the local server with Xpra
	xpra attach \
		--key-shortcut 'Control_R:toggle_keyboard_grab' \
		--notifications=no \
		--speaker=no \
		--system-tray=no \
		--webcam=no \
		--xsettings=no \
		"ssh://admin@${SL_REMOTE_HOST}:2000/42"

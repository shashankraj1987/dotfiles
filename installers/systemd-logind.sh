#!/usr/bin/env bash
# Optionally keeps a GNOME laptop awake when its lid is closed.

configure_gnome_auto_suspend() {
    local schema="org.gnome.settings-daemon.plugins.power"

    if ! has_command gsettings || ! gsettings list-schemas | grep -qx "$schema"; then
        write_skip "GNOME power settings are unavailable; skipping automatic-suspend settings."
        return
    fi

    local key current
    for key in sleep-inactive-ac-type sleep-inactive-battery-type; do
        if [ "$(gsettings writable "$schema" "$key" 2>/dev/null)" != "true" ]; then
            write_warn "GNOME setting $key is locked; leaving it unchanged."
            continue
        fi

        current="$(gsettings get "$schema" "$key")"
        if [ "$current" = "'nothing'" ]; then
            write_skip "GNOME setting $key already disables automatic suspend."
            continue
        fi

        gsettings set "$schema" "$key" nothing
        write_success "Disabled GNOME automatic suspend for $key."
    done
}

step_systemd_logind() {
    local source="$REPO_ROOT/config/linux/systemd/logind.conf.d/lid.conf"
    local destination="/etc/systemd/logind.conf.d/lid.conf"
    local systemd_changed=false

    if ! has_command systemctl; then
        write_warn "systemctl is unavailable; skipping the lid-switch configuration."
        return
    fi

    if [ ! -f "$source" ]; then
        write_warn "Missing systemd-logind configuration: $source"
        return
    fi

    if [ -f "$destination" ] && cmp -s "$source" "$destination"; then
        write_skip "$destination is already current."
    else
        if [ -e "$destination" ]; then
            local backup="${destination}.$(date +%Y%m%d-%H%M%S).bak"
            sudo cp -p "$destination" "$backup"
            write_step "Backed up the existing configuration to $backup."
        fi

        sudo install -D -m 0644 "$source" "$destination"
        write_success "Updated $destination."
        systemd_changed=true
    fi

    if $systemd_changed; then
        write_warn "Restarting systemd-logind may interrupt the current desktop session."
        sudo systemctl restart systemd-logind.service
        write_success "Restarted systemd-logind."
    fi

    configure_gnome_auto_suspend
}

register_step "systemd_logind"

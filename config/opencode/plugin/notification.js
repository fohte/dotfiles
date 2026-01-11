// OpenCode notification plugin
//
// Sends macOS push notification when session becomes idle.
// Clicking the notification will jump to the tmux session/window/pane.
//
// Requirements:
//   - terminal-notifier
//   - tmux

export const NotificationPlugin = async ({ $, directory }) => {
  return {
    event: async ({ event }) => {
      if (event.type === 'session.idle') {
        try {
          // Get tmux session info
          const tmuxSession = await $`tmux display-message -p '#S'`
            .text()
            .catch(() => '')
          const tmuxWindow = await $`tmux display-message -p '#I'`
            .text()
            .catch(() => '')
          const tmuxPane = await $`tmux display-message -p '#P'`
            .text()
            .catch(() => '')

          // Skip if not in tmux
          if (!tmuxSession.trim()) {
            return
          }

          const title = `OpenCode [${tmuxSession.trim()}]`
          const message = 'Session completed'

          // Build the command to execute when notification is clicked
          const clickCommand = `zsh -c "client_name=\\$(tmux list-clients -F '#{client_name}' | head -n1); tmux switch-client -c \\"\\$client_name\\" -t '${tmuxSession.trim()}:${tmuxWindow.trim()}.${tmuxPane.trim()}'; open -a WezTerm"`

          await $`terminal-notifier -title ${title} -message ${message} -sound Glass -execute ${clickCommand}`
        } catch (error) {
          // Silently ignore notification errors
        }
      }
    },
  }
}

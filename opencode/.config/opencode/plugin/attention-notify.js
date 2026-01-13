export const AttentionNotify = async ({ $ }) => {
  const getFocusedWindow = async () => {
    try {
      const focusedWindow = await $`niri msg --json focused-window`.text();
      return JSON.parse(focusedWindow);
    } catch (error) {
      return null;
    }
  };

  const selfWindow = await getFocusedWindow();
  const selfWindowId = selfWindow?.id ?? null;

  const isOpencodeFocused = async () => {
    const focusedWindow = await getFocusedWindow();
    if (!focusedWindow) {
      return false;
    }

    if (selfWindowId === null) {
      return false;
    }

    return focusedWindow.id === selfWindowId;
  };

  const playSound = async () => {
    await $`paplay /usr/share/sounds/freedesktop/stereo/complete.oga`;
  };

  const notify = async (title, message) => {
    try {
      if (await isOpencodeFocused()) {
        return;
      }

      await $`notify-send ${title} ${message}`;
      await playSound();
    } catch (error) {
      console.error("Notification failed", error);
    }
  };

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("opencode", "Session completed");
      }

      if (event.type === "session.error") {
        await notify("opencode", "Session error");
      }

      if (event.type === "permission.updated") {
        const status = event.permission?.status;
        const needsAttention =
          !status || status === "pending" || status === "requested";
        if (needsAttention) {
          await notify("opencode", "Permission requested");
        }
      }
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        await notify("opencode", "Question requested");
      }
    },
  };
};

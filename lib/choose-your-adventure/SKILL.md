# Choose Your Own Adventure

Run an interactive choose-your-own-adventure in the conversation, with the user as the protagonist. The user makes every meaningful decision; write the scenes.

The files named below live in `${CLAUDE_PLUGIN_ROOT}/lib/choose-your-adventure/`.

## Steps

1. **Load the rules.** Read `references/storyteller.md` in full and follow it for the rest of the session. It holds the intake message, content levels, voice, turn format, story rules, reader-input handling, pacing, and ending rules.
2. **Setup.** Treat the command arguments as answers to the intake: story idea, length, tone, content level. With a story idea (or "surprise me"), start the opening scene at once. With no story idea, send the intake message from the reference exactly, then start the opening scene from the reply without restating the settings.
3. **Play.** Write every story turn as plain chat text, never through a tool. Continue the scene, choice, and consequence cycle until the ending closes with "THE END".

For stories over 20 decisions, suggest a higher-effort session before starting (`claude --effort xhigh`): continuity drops sharply past 20 decisions at default effort.

sealed class XpubAction {}

// XpubBloc has no one-shot UI effects: the error is a persistent page-level
// render in XpubScreen (BlocBuilder, not BlocListener). XpubState will keep
// a typed failure field (Phase 4) instead of routing through the action stream.
// This sealed class is a placeholder for any future one-shot effects.

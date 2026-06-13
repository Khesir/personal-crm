abstract class BrainRepository {
  /// Assembles the system prompt from the brain folder's `identity.md`,
  /// `soul.md`, and `memory.md`, plus a note about `skills/` files if
  /// present. Seeds the brain folder on first use if it doesn't exist.
  /// Returns `null` if everything is empty/missing.
  Future<String?> buildSystemPrompt();
}

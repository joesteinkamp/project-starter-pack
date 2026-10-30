export function parsePlainText(input: unknown): Book {
  if (typeof input !== "string" || input.trim() === "") {
    throw new ImportError("A plain-text book must be a non-empty file.");
  }
  return { title: firstLine(input), chapters: splitChapters(input) };
}

export function parsePlainText(input: unknown): Book {
  const text = input as string;
  if (text.trim() === "") {
    throw new ImportError("A plain-text book must be a non-empty file.");
  }
  return { title: firstLine(text), chapters: splitChapters(text) };
}

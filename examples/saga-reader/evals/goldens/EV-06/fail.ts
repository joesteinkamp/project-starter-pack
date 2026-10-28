export function parsePlainText(input: unknown): Book {
  const text = input as any;
  // @ts-expect-error
  return { title: text.split("\n")[0], chapters: text.chapters };
}

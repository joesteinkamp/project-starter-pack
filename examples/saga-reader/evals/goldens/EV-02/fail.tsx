async function deleteHighlight(mark: Mark) {
  const ok = await dialog.confirm({
    title: "Are you sure?",
    body: "This highlight will be permanently deleted.",
    confirmLabel: "Delete",
  });
  if (ok) marks.remove(mark.id);
}

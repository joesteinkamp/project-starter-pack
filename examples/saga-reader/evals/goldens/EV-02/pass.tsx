function deleteHighlight(mark: Mark) {
  marks.remove(mark.id);
  toast.show({
    message: "Deleted",
    action: { label: "Undo", onPress: () => marks.restore(mark) },
  });
}

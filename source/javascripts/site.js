// From https://tavern-wenches.com/

document.addEventListener('keydown', (event) => {
  const keyName = event.key;
  switch (keyName) {
    case "ArrowLeft":
      document.getElementsByClassName('prev_link')[0].click();
      return;
    case "ArrowRight":
      document.getElementsByClassName('next_link')[0].click();
      return;
    default:
      return;
  }
});

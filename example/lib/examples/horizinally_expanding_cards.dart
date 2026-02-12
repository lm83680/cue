// Row(
// mainAxisAlignment: .center,
// children: [
// for (final i in [0])
// Cue.onToggle(
// toggled: i == _expandedIndex,
// duration: const Duration(milliseconds: 500),
// child: Card(
// elevation: .5,
// clipBehavior: .antiAlias,
// child: Actor(
// act: Resize(
// from: Size(expandedWidth / 4, 200),
// to: Size(expandedWidth, 200),
// ),
// child: DecoratedBox(
// decoration: BoxDecoration(
// borderRadius: BorderRadius.circular(12),
// color: [Colors.red, Colors.green, Colors.blue][i].shade400,
// backgroundBlendMode: BlendMode.multiply,
// image: DecorationImage(
// image: NetworkImage('https://picsum.photos/id/${i + 400}/400/300'),
// fit: BoxFit.cover,
// opacity: .5,
// ),
// ),
// child: InkWell(
// onTap: () => setState(() {
// if (_expandedIndex == i) {
// _expandedIndex = -1;
// return;
// }
// _expandedIndex = i;
// }),
// child: Padding(
// padding: const EdgeInsets.all(12.0),
// child: Column(
// mainAxisAlignment: .end,
// crossAxisAlignment: .center,
// children: [
// Actor.all(
// acts: [
// Translate.y(begin: 20, timing: .startAt(.2)),
// Rotate.turns(from: -1),
// Anchor(
// begin: Alignment.bottomCenter,
// end: Alignment.bottomLeft,
// timing: .endAt(.2),
// ),
// ],
// child: Text(
// ['Cool', 'Elegant', 'Awesome'][i],
// style: textTheme.titleMedium?.copyWith(
// color: Colors.white,
// fontWeight: FontWeight.bold,
// ),
// ),
// ),
// SizedBox(height: 2),
// Actor.all(
// acts: [
// Fade(),
// Translate.y(begin: 50, timing: .startAt(.5)),
// ],
// child: Text(
// 'This is a bunch of text that should only be visible when the card is expanded.',
// style: textTheme.bodyMedium?.copyWith(color: Colors.white),
// ),
// ),
// ],
// ),
// ),
// ),
// ),
// ),
// ),
// ),
// ],
// ),

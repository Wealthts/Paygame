import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'ทั้งหมด';

  final List<_Game> _games = const [
    _Game('RoV', 'RoV', Color(0xFFB20F20), Colors.white, 'มือถือ', true),
    _Game('Free Fire', 'FF', Color(0xFFD9AA27), Color(0xFF4C3100), 'มือถือ', true),
    _Game('PUBG Mobile', 'PG', Color(0xFF790D15), Color(0xFFFFCE61), 'มือถือ', true),
    _Game('Genshin Impact', 'GI', Color(0xFFF4E5C6), Color(0xFF8B1720), 'มือถือ', false),
    _Game('Valorant', 'VP', Color(0xFF211C1A), Color(0xFFE7C659), 'PC', true),
    _Game('MLBB', 'ML', Color(0xFFFFDEE1), Color(0xFF87121C), 'มือถือ', false),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visibleGames = _games.where((game) {
      final matchesSearch = game.name.toLowerCase().contains(query);
      final matchesCategory = _category == 'ทั้งหมด' ||
          (_category == 'ยอดนิยม' ? game.popular : game.category == _category);
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFB20F20),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('สวัสดี,', style: TextStyle(color: Colors.white, fontSize: 13)),
                          Text('[ชื่อผู้ใช้]', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFDDAE2C), borderRadius: BorderRadius.circular(30)),
                        child: const Row(children: [
                          Icon(Icons.monetization_on_outlined, size: 20, color: Color(0xFF4C3100)),
                          SizedBox(width: 6),
                          Text('1,250 แต้ม', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3100))),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาเกม...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF780C14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDAE2C), width: 2),
                    ),
                    child: Row(children: [
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('โปรโมชั่นวันนี้', style: TextStyle(color: Color(0xFFFFCE61), fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('เติมครบ 300 บาท\nรับแต้ม x2', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, height: 1.25)),
                          SizedBox(height: 6),
                          Text('ถึง [วันที่สิ้นสุด]', style: TextStyle(color: Color(0xFFFFC8C8), fontSize: 12)),
                        ],
                      )),
                      CircleAvatar(radius: 39, backgroundColor: const Color(0xFFDDAE2C), child: const Text('x2', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF780C14)))),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: ['ทั้งหมด', 'มือถือ', 'PC', 'ยอดนิยม'].map((category) {
                      final selected = category == _category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) => setState(() => _category = category),
                          selectedColor: const Color(0xFFB20F20),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF665F5C)),
                          showCheckmark: false,
                          side: BorderSide(color: selected ? const Color(0xFFB20F20) : const Color(0xFFE7DED5)),
                        ),
                      );
                    }).toList()),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('เลือกเกม', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF29211F))),
                    TextButton(onPressed: () => setState(() { _category = 'ทั้งหมด'; _searchController.clear(); }), child: const Text('ดูทั้งหมด', style: TextStyle(color: Color(0xFFB20F20), decoration: TextDecoration.underline))),
                  ]),
                  const SizedBox(height: 10),
                  if (visibleGames.isEmpty)
                    const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('ไม่พบเกมที่ค้นหา')))
                  else
                    LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth > 650 ? 5 : 3;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleGames.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.86,
                        ),
                        itemBuilder: (context, index) {
                          final game = visibleGames[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เลือก ${game.name} แล้ว (หน้าราคาเติมเกมยังไม่ได้เชื่อม)'))),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1E9E3))),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                AspectRatio(aspectRatio: 1, child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: game.color, borderRadius: BorderRadius.circular(17)),
                                  child: Text(game.shortName, style: TextStyle(color: game.textColor, fontSize: 20, fontWeight: FontWeight.w900)),
                                )),
                                const SizedBox(height: 8),
                                Text(game.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.1)),
                              ]),
                            ),
                          );
                        },
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Game {
  final String name;
  final String shortName;
  final Color color;
  final Color textColor;
  final String category;
  final bool popular;

  const _Game(this.name, this.shortName, this.color, this.textColor, this.category, this.popular);
}

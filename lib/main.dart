import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() {
  runZonedGuarded(
    () => runApp(
      ChangeNotifierProvider(
        create: (_) => AppState()..initialize(),
        child: const BiteLocalApp(),
      ),
    ),
    (error, stack) => debugPrint('Unhandled app error: $error\n$stack'),
  );
}

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.emoji,
    required this.rating,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String emoji;
  final double rating;
}

const menu = <FoodItem>[
  FoodItem(
    id: 'spicy-bowl',
    name: 'Spicy Tofu Bowl',
    description: 'Crispy tofu, jasmine rice, pickled vegetables',
    price: 299,
    category: 'Popular',
    emoji: '🥗',
    rating: 4.9,
  ),
  FoodItem(
    id: 'truffle-pasta',
    name: 'Truffle Mushroom Pasta',
    description: 'Creamy sauce, parmesan, fresh herbs',
    price: 399,
    category: 'Popular',
    emoji: '🍝',
    rating: 4.8,
  ),
  FoodItem(
    id: 'salmon-roll',
    name: 'Salmon Avocado Roll',
    description: 'Eight pieces with sesame and soy',
    price: 449,
    category: 'Sushi',
    emoji: '🍣',
    rating: 4.7,
  ),
  FoodItem(
    id: 'mango-smoothie',
    name: 'Mango Matcha Smoothie',
    description: 'Fresh mango, oat milk, ceremonial matcha',
    price: 199,
    category: 'Drinks',
    emoji: '🥭',
    rating: 4.9,
  ),
  FoodItem(
    id: 'churros',
    name: 'Cinnamon Churros',
    description: 'Warm churros with dark chocolate dip',
    price: 249,
    category: 'Desserts',
    emoji: '🍩',
    rating: 4.6,
  ),
];

class AppState extends ChangeNotifier {
  final Map<String, int> _cart = {};
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  int tabIndex = 0;
  String selectedCategory = 'Popular';
  bool isLoading = false;
  String? locationLabel = 'Set your delivery location';
  String? avatarPath;
  String? errorMessage;

  int quantityFor(FoodItem item) => _cart[item.id] ?? 0;

  List<FoodItem> get visibleItems => menu
      .where((item) =>
          selectedCategory == 'Popular' || item.category == selectedCategory)
      .toList();

  int get cartCount => _cart.values.fold(0, (sum, count) => sum + count);

  double get subtotal => menu.fold(
        0,
        (total, item) => total + item.price * quantityFor(item),
      );

  double get deliveryFee => cartCount == 0 ? 0 : 49;
  double get total => subtotal + deliveryFee;

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    try {
      await _notifications.initialize(settings);
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
    }
  }

  void add(FoodItem item) {
    _cart[item.id] = quantityFor(item) + 1;
    notifyListeners();
  }

  void remove(FoodItem item) {
    final next = quantityFor(item) - 1;
    if (next <= 0) {
      _cart.remove(item.id);
    } else {
      _cart[item.id] = next;
    }
    notifyListeners();
  }

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> selectLocation() async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        errorMessage = 'Location permission is needed to find nearby delivery.';
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      locationLabel =
          '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
    } catch (error) {
      errorMessage = 'Could not get your location. Please try again.';
      debugPrint('Location error: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> chooseAvatar(ImageSource source) async {
    try {
      final status = source == ImageSource.camera
          ? await Permission.camera.request()
          : await Permission.photos.request();
      if (!status.isGranted) {
        errorMessage = 'Permission was not granted for this action.';
        notifyListeners();
        return;
      }
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 80,
      );
      avatarPath = image?.path;
      notifyListeners();
    } catch (error) {
      errorMessage = 'We could not open the image picker.';
      debugPrint('Image picker error: $error');
      notifyListeners();
    }
  }

  Future<void> placeOrder() async {
    if (cartCount == 0) return;
    isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      await _notifications.show(
        1,
        'Order confirmed',
        'Your order is being prepared by the kitchen.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'orders',
            'Order updates',
            channelDescription: 'Updates about your Bite Local order',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      _cart.clear();
    } catch (error) {
      errorMessage = 'Order saved, but we could not send a notification.';
      debugPrint('Order notification error: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class BiteLocalApp extends StatelessWidget {
  const BiteLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bite Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF694A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF8),
        useMaterial3: true,
        fontFamily: 'sans',
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pages = [
      const HomeScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[state.tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.setTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DELIVERING TO', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: Colors.grey[600])),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: state.selectLocation,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFF694A), size: 18),
                            const SizedBox(width: 4),
                            Flexible(child: Text(state.locationLabel ?? '', style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _showCart(context), icon: Badge(label: Text('${state.cartCount}'), isLabelVisible: state.cartCount > 0, child: const Icon(Icons.shopping_bag_outlined))),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 25, 22, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: const Color(0xFF242B35), borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('20% OFF', style: TextStyle(color: Color(0xFFFFC857), fontSize: 27, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Your first order\nwith code FRESH20', style: TextStyle(color: Colors.white, height: 1.4)), SizedBox(height: 14), Text('Claim offer  →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])),
                  const Text('🥡', style: TextStyle(fontSize: 66)),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
          sliver: SliverToBoxAdapter(child: Text('What are you craving?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              children: ['Popular', 'Sushi', 'Drinks', 'Desserts'].map((category) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(label: Text(category), selected: state.selectedCategory == category, onSelected: (_) => state.setCategory(category)),
              )).toList(),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          sliver: SliverList.builder(
            itemCount: state.visibleItems.length,
            itemBuilder: (context, index) => FoodCard(item: state.visibleItems[index]),
          ),
        ),
      ],
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const CartSheet());
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({required this.item, super.key});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final quantity = state.quantityFor(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))]),
      child: Row(
        children: [
          Container(width: 82, height: 82, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFFEEE8), borderRadius: BorderRadius.circular(15)), child: Text(item.emoji, style: const TextStyle(fontSize: 42))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.star, size: 15, color: Color(0xFFFFB800)), Text(' ${item.rating}', style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
          ])),
          const SizedBox(width: 6),
          quantity == 0
              ? IconButton.filled(onPressed: () => state.add(item), icon: const Icon(Icons.add))
              : Row(children: [IconButton(onPressed: () => state.remove(item), icon: const Icon(Icons.remove_circle_outline)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)), IconButton(onPressed: () => state.add(item), icon: const Icon(Icons.add_circle, color: Color(0xFFFF694A)))]),
        ],
      ),
    );
  }
}

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = menu.where((item) => state.quantityFor(item) > 0).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your order', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Your bag is waiting for something delicious.')),
        ...items.map((item) => ListTile(contentPadding: EdgeInsets.zero, title: Text(item.name), subtitle: Text('${state.quantityFor(item)} × ₹${item.price.toStringAsFixed(0)}'), trailing: Text('₹${(state.quantityFor(item) * item.price).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)))),
        if (items.isNotEmpty) ...[
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)), Text('₹${state.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: state.isLoading ? null : () async { await state.placeOrder(); if (context.mounted) Navigator.pop(context); }, child: Text(state.isLoading ? 'Confirming...' : 'Place order'))),
        ],
      ]),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(height: 18), Text('Orders', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 24), _OrderCard()]));
}

class _OrderCard extends StatelessWidget {
  const _OrderCard();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Text('🥗', style: TextStyle(fontSize: 40)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your first order is waiting', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Place an order to see live updates here.', style: TextStyle(color: Colors.grey))]))]));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(padding: const EdgeInsets.all(22), children: [
      const SizedBox(height: 18),
      const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 22),
      Center(child: Stack(children: [
        CircleAvatar(radius: 48, backgroundColor: const Color(0xFFFFEEE8), child: state.avatarPath == null ? const Text('🙂', style: TextStyle(fontSize: 42)) : const Icon(Icons.person, size: 50)),
        Positioned(bottom: 0, right: 0, child: IconButton.filled(onPressed: () => _showAvatarOptions(context), icon: const Icon(Icons.camera_alt, size: 18))),
      ])),
      const SizedBox(height: 12),
      const Center(child: Text('Alex Morgan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19))),
      const SizedBox(height: 28),
      Card(child: Column(children: const [ListTile(leading: Icon(Icons.favorite_border), title: Text('Saved restaurants'), trailing: Icon(Icons.chevron_right)), ListTile(leading: Icon(Icons.credit_card), title: Text('Payment methods'), trailing: Icon(Icons.chevron_right)), ListTile(leading: Icon(Icons.notifications_none), title: Text('Notification preferences'), trailing: Icon(Icons.chevron_right))])),
      if (state.errorMessage != null) Padding(padding: const EdgeInsets.only(top: 18), child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ]);
  }

  void _showAvatarOptions(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take a photo'), onTap: () { Navigator.pop(context); state.chooseAvatar(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from gallery'), onTap: () { Navigator.pop(context); state.chooseAvatar(ImageSource.gallery); }),
    ])));
  }
}

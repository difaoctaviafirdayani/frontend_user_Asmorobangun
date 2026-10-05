String _s(dynamic v, [String d = '']) => v == null ? d : v.toString();
int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : (int.tryParse(_s(v)) ?? d);
int? _in(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(_s(v)));
double? _dn(dynamic v) => v is num ? v.toDouble() : double.tryParse(_s(v));
List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];

class AppUser {
  final String id, name, email, phone, role;
  final String? avatar;
  AppUser({required this.id, required this.name, required this.email, required this.phone, required this.role, this.avatar});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _s(j['id']),
        name: _s(j['name']),
        email: _s(j['email']),
        phone: _s(j['phone']),
        role: _s(j['role'], 'member'),
        avatar: j['avatar'] == null ? null : _s(j['avatar']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'email': email, 'phone': phone, 'role': role, 'avatar': avatar};
}

class Facility {
  final String id, name, category, shortDesc, longDesc, priceInfo, image, bookingType;
  final int? price;
  final double? avgRating;
  final int reviewCount;
  final Map<String, dynamic> paymentMethods;
  Facility({
    required this.id,
    required this.name,
    required this.category,
    required this.shortDesc,
    required this.longDesc,
    required this.priceInfo,
    required this.image,
    required this.bookingType,
    this.price,
    this.avgRating,
    this.reviewCount = 0,
    this.paymentMethods = const {},
  });

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: _s(j['id']),
        name: _s(j['name']),
        category: _s(j['category']),
        shortDesc: _s(j['shortDesc']),
        longDesc: _s(j['longDesc']),
        priceInfo: _s(j['priceInfo']),
        image: _s(j['image']),
        bookingType: _s(j['bookingType']),
        price: _in(j['price']),
        avgRating: _dn(j['avgRating']),
        reviewCount: _i(j['reviewCount']),
        paymentMethods: j['paymentMethods'] is Map<String, dynamic> ? j['paymentMethods'] as Map<String, dynamic> : {},
      );
}

class Review {
  final String id, userName, comment, date;
  final int rating;
  Review({required this.id, required this.userName, required this.comment, required this.date, required this.rating});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: _s(j['id']),
        userName: _s(j['userName']),
        comment: _s(j['comment']),
        date: _s(j['date']),
        rating: _i(j['rating']),
      );
}

class Topeng {
  final String id, name, character, color, image, desc;
  final int price, stock;
  Topeng({required this.id, required this.name, required this.character, required this.color, required this.image, required this.desc, required this.price, required this.stock});
  factory Topeng.fromJson(Map<String, dynamic> j) => Topeng(
        id: _s(j['id']),
        name: _s(j['name']),
        character: _s(j['character']),
        color: _s(j['color']),
        image: _s(j['image']),
        desc: _s(j['desc']),
        price: _i(j['price']),
        stock: _i(j['stock']),
      );
}

class Article {
  final String id, slug, title, excerpt, content, image, category, author, date;
  Article({required this.id, required this.slug, required this.title, required this.excerpt, required this.content, required this.image, required this.category, required this.author, required this.date});
  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: _s(j['id']),
        slug: _s(j['slug']),
        title: _s(j['title']),
        excerpt: _s(j['excerpt']),
        content: _s(j['content']),
        image: _s(j['image']),
        category: _s(j['category']),
        author: _s(j['author']),
        date: _s(j['date']),
      );
}

class Announcement {
  final String id, title, body, type, date;
  final String? image;
  Announcement({required this.id, required this.title, required this.body, required this.type, required this.date, this.image});
  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: _s(j['id']),
        title: _s(j['title']),
        body: _s(j['body']),
        type: _s(j['type'], 'Pengumuman'),
        date: _s(j['date']),
        image: j['image'] == null ? null : _s(j['image']),
      );
}

class GalleryItem {
  final String id, title, caption, image, date;
  GalleryItem({required this.id, required this.title, required this.caption, required this.image, required this.date});
  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
        id: _s(j['id']),
        title: _s(j['title']),
        caption: _s(j['caption']),
        image: _s(j['image']),
        date: _s(j['date']),
      );
}

class ThreadSummary {
  final String id, category, title, userName, date;
  final int replyCount;
  ThreadSummary({required this.id, required this.category, required this.title, required this.userName, required this.date, required this.replyCount});
  factory ThreadSummary.fromJson(Map<String, dynamic> j) => ThreadSummary(
        id: _s(j['id']),
        category: _s(j['category']),
        title: _s(j['title']),
        userName: _s(j['userName']),
        date: _s(j['date']),
        replyCount: _i(j['replyCount']),
      );
}

class Reply {
  final String id, userName, content, date;
  Reply({required this.id, required this.userName, required this.content, required this.date});
  factory Reply.fromJson(Map<String, dynamic> j) =>
      Reply(id: _s(j['id']), userName: _s(j['userName']), content: _s(j['content']), date: _s(j['date']));
}

class ForumThread {
  final String id, category, title, userName, content, date;
  final List<Reply> replies;
  ForumThread({required this.id, required this.category, required this.title, required this.userName, required this.content, required this.date, required this.replies});
  factory ForumThread.fromJson(Map<String, dynamic> j) => ForumThread(
        id: _s(j['id']),
        category: _s(j['category']),
        title: _s(j['title']),
        userName: _s(j['userName']),
        content: _s(j['content']),
        date: _s(j['date']),
        replies: _list(j['replies']).map(Reply.fromJson).toList(),
      );
}

class Booking {
  final String id, facilityId, facilityName, bookingType, notes, status, createdAt;
  final String? date, eventType, location, paymentMethod, proofFile;
  final int? amount;
  Booking({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.bookingType,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.date,
    this.eventType,
    this.location,
    this.paymentMethod,
    this.proofFile,
    this.amount,
  });
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: _s(j['id']),
        facilityId: _s(j['facilityId']),
        facilityName: _s(j['facilityName']),
        bookingType: _s(j['bookingType']),
        notes: _s(j['notes']),
        status: _s(j['status']),
        createdAt: _s(j['createdAt']),
        date: j['date'] == null ? null : _s(j['date']),
        eventType: j['eventType'] == null ? null : _s(j['eventType']),
        location: j['location'] == null ? null : _s(j['location']),
        paymentMethod: j['paymentMethod'] == null ? null : _s(j['paymentMethod']),
        proofFile: j['proofFile'] == null ? null : _s(j['proofFile']),
        amount: _in(j['amount']),
      );
}

class ChatMsg {
  final String from, text, date;
  ChatMsg({required this.from, required this.text, required this.date});
  factory ChatMsg.fromJson(Map<String, dynamic> j) =>
      ChatMsg(from: _s(j['from']), text: _s(j['text']), date: _s(j['date']));
}

class TopengOrder {
  final String id, topengId, topengName, topengImage, message, status, createdAt;
  final int qty, unitPrice, total;
  final String? customName, customDesign, paymentMethod, proofFile;
  final List<ChatMsg> chatLog;
  TopengOrder({
    required this.id,
    required this.topengId,
    required this.topengName,
    required this.topengImage,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.qty,
    required this.unitPrice,
    required this.total,
    required this.chatLog,
    this.customName,
    this.customDesign,
    this.paymentMethod,
    this.proofFile,
  });
  factory TopengOrder.fromJson(Map<String, dynamic> j) => TopengOrder(
        id: _s(j['id']),
        topengId: _s(j['topengId']),
        topengName: _s(j['topengName']),
        topengImage: _s(j['topengImage']),
        message: _s(j['message']),
        status: _s(j['status']),
        createdAt: _s(j['createdAt']),
        qty: _i(j['qty'], 1),
        unitPrice: _i(j['unitPrice']),
        total: _i(j['total']),
        chatLog: _list(j['chatLog']).map(ChatMsg.fromJson).toList(),
        customName: j['customName'] == null ? null : _s(j['customName']),
        customDesign: j['customDesign'] == null ? null : _s(j['customDesign']),
        paymentMethod: j['paymentMethod'] == null ? null : _s(j['paymentMethod']),
        proofFile: j['proofFile'] == null ? null : _s(j['proofFile']),
      );
}

class SearchHit {
  final String id, title, type;
  final String? slug, image;
  SearchHit({required this.id, required this.title, required this.type, this.slug, this.image});
  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        id: _s(j['id']),
        title: _s(j['title']),
        type: _s(j['type']),
        slug: j['slug'] == null ? null : _s(j['slug']),
        image: j['image'] == null ? null : _s(j['image']),
      );
}

List<T> mapList<T>(dynamic v, T Function(Map<String, dynamic>) f) => _list(v).map(f).toList();

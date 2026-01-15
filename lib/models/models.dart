import 'package:flutter/material.dart';

// ==========================
// ENUMS
// ==========================

enum EventMode { ONLINE, OFFLINE, HYBRID }

enum EventCategory {
  HACKATHON,
  WORKSHOP,
  CONFERENCE,
  MEETUP,
  WEBINAR,
  SEMINAR,
  BOOTCAMP,
  STARTUP_PITCH,
  COMPETITION,
  CULTURAL_FEST,
  SPORTS_EVENT,
  CAREER_FAIR,
  NETWORKING,
  PRODUCT_LAUNCH,
  SUMMIT,
  DEMO_DAY,
  OTHER,
}

enum EventVisibility { PUBLIC, PRIVATE, UNLISTED }

enum EventStatus { DRAFT, PUBLISHED, ONGOING, COMPLETED, CANCELLED }

enum RegistrationStatus { PENDING, CONFIRMED, WAITLISTED, CANCELLED }

// ==========================
// SUPPORTING CLASSES
// ==========================

class EventBranding {
  final String bannerUrl;
  final String logoUrl;
  final String? primaryColor;
  final String? secondaryColor;

  const EventBranding({
    required this.bannerUrl,
    required this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  Map<String, dynamic> toJson() => {
    'banner_url': bannerUrl,
    'logo_url': logoUrl,
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
  };

  factory EventBranding.fromJson(Map<String, dynamic> json) => EventBranding(
    bannerUrl: json['banner_url'] as String,
    logoUrl: json['logo_url'] as String,
    primaryColor: json['primary_color'] as String?,
    secondaryColor: json['secondary_color'] as String?,
  );
}

class Organization {
  final String id;
  final String name;
  final String slug;
  final String logoUrl;
  final String verificationStatus;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.verificationStatus,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo_url': logoUrl,
    'verification_status': verificationStatus,
  };

  factory Organization.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v, [String d = '']) => v is String ? v : (v?.toString() ?? d);
    return Organization(
      id: _s(json['id']),
      name: _s(json['name'], 'Unknown Organization'),
      slug: _s(json['slug']),
      logoUrl: _s(json['logo_url']),
      verificationStatus: _s(json['verification_status'], 'PENDING'),
    );
  }
}

// ==========================
// MODELS
// ==========================

class Event {
  final String id;
  final String name;
  final String? description;
  final EventMode mode;
  final EventCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final int? capacity;
  final EventVisibility visibility;
  final EventStatus status;
  final String? landingPageSlug;
  final EventBranding branding;
  final Organization organization;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.name,
    required this.description,
    required this.mode,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.visibility,
    required this.status,
    required this.landingPageSlug,
    required this.branding,
    required this.organization,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'mode': mode.name,
    'category': category.name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'capacity': capacity,
    'visibility': visibility.name,
    'status': status.name,
    'landing_page_slug': landingPageSlug,
    'branding': branding.toJson(),
    'organization_id': organization.id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v, [String d = '']) => v is String ? v : (v?.toString() ?? d);
    DateTime _dt(dynamic v, [DateTime? d]) {
      if (v == null) return d ?? DateTime.now();
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) { return d ?? DateTime.now(); }
      }
      return d ?? DateTime.now();
    }

    // Parse branding JSON
    EventBranding? branding;
    final rawBranding = json['branding'];
    if (rawBranding is Map) {
      final brandingData = Map<String, dynamic>.from(rawBranding);
      if (brandingData.isNotEmpty) {
        try { branding = EventBranding.fromJson(brandingData); } catch (_) {}
      }
    }
    
    // Parse organization
    Organization? organization;
    final rawOrg = json['organization'];
    if (rawOrg is Map) {
      try { organization = Organization.fromJson(Map<String, dynamic>.from(rawOrg)); } catch (_) {}
    }
    
    final modeStr = _s(json['mode']).toUpperCase();
    final visStr = _s(json['visibility']).toUpperCase();
    final statusStr = _s(json['status']).toUpperCase();
    final catStr = _s(json['category']).toUpperCase();

    EventMode mode = EventMode.ONLINE;
    for (final m in EventMode.values) { if (m.name == modeStr) { mode = m; break; } }

    EventVisibility visibility = EventVisibility.PUBLIC;
    for (final v in EventVisibility.values) { if (v.name == visStr) { visibility = v; break; } }

    EventStatus status = EventStatus.PUBLISHED;
    for (final s in EventStatus.values) { if (s.name == statusStr) { status = s; break; } }

    EventCategory category = EventCategory.OTHER;
    for (final c in EventCategory.values) { if (c.name == catStr) { category = c; break; } }

    final start = _dt(json['start_date']);
    final end = _dt(json['end_date'], start.add(const Duration(hours: 2)));

    return Event(
      id: _s(json['id']),
      name: _s(json['name'], 'Untitled Event'),
      description: json['description'] as String?,
      mode: mode,
      category: category,
      startDate: start,
      endDate: end,
      capacity: json['capacity'] is int ? json['capacity'] as int : (json['capacity'] as num?)?.toInt(),
      visibility: visibility,
      status: status,
      landingPageSlug: json['landing_page_slug'] as String?,
      branding: branding ?? const EventBranding(
        bannerUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
        logoUrl: 'https://images.unsplash.com/photo-1599305445671-ac291c95aaa9',
      ),
      organization: organization ?? const Organization(
        id: '',
        name: 'Unknown Organization',
        slug: 'unknown',
        logoUrl: '',
        verificationStatus: 'PENDING',
      ),
      createdAt: _dt(json['created_at'], start),
      updatedAt: _dt(json['updated_at'], start),
    );
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    EventMode? mode,
    EventCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    EventVisibility? visibility,
    EventStatus? status,
    String? landingPageSlug,
    EventBranding? branding,
    Organization? organization,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Event(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    mode: mode ?? this.mode,
    category: category ?? this.category,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    capacity: capacity ?? this.capacity,
    visibility: visibility ?? this.visibility,
    status: status ?? this.status,
    landingPageSlug: landingPageSlug ?? this.landingPageSlug,
    branding: branding ?? this.branding,
    organization: organization ?? this.organization,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class TicketTier {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int? quantity;
  final int soldCount;
  final DateTime? saleStart;
  final DateTime? saleEnd;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketTier({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.soldCount,
    required this.saleStart,
    required this.saleEnd,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFree => price == 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'name': name,
    'description': description,
    'price': price,
    'currency': currency,
    'quantity': quantity,
    'sold_count': soldCount,
    'sale_start': saleStart?.toIso8601String(),
    'sale_end': saleEnd?.toIso8601String(),
    'is_active': isActive,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v, [String d = '']) => v is String ? v : (v?.toString() ?? d);
    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      if (v is String) { try { return DateTime.parse(v); } catch (_) { return null; } }
      return null;
    }
    double _d(dynamic v, [double d = 0]) => v is num ? v.toDouble() : d;
    int? _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

    return TicketTier(
      id: _s(json['id']),
      eventId: _s(json['event_id']),
      name: _s(json['name'], 'General'),
      description: json['description'] as String?,
      price: _d(json['price']),
      currency: _s(json['currency'], 'INR'),
      quantity: _i(json['quantity']),
      soldCount: _i(json['sold_count']) ?? 0,
      saleStart: _dt(json['sale_start']),
      saleEnd: _dt(json['sale_end']),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      sortOrder: _i(json['sort_order']) ?? 0,
      createdAt: _dt(json['created_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']) ?? DateTime.now(),
    );
  }

  TicketTier copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? quantity,
    int? soldCount,
    DateTime? saleStart,
    DateTime? saleEnd,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TicketTier(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    quantity: quantity ?? this.quantity,
    soldCount: soldCount ?? this.soldCount,
    saleStart: saleStart ?? this.saleStart,
    saleEnd: saleEnd ?? this.saleEnd,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Registration {
  final String id;
  final String eventId;
  final String userId;
  final String? ticketTierId;
  final RegistrationStatus status;
  final int quantity;
  final Map<String, dynamic> formResponses;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String? promoCodeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketTierId,
    required this.status,
    this.quantity = 1,
    required this.formResponses,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.promoCodeId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'user_id': userId,
    'ticket_tier_id': ticketTierId,
    'status': status.name,
    'quantity': quantity,
    'form_responses': formResponses,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'total_amount': totalAmount,
    'promo_code_id': promoCodeId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Registration.fromJson(Map<String, dynamic> json) => Registration(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    userId: json['user_id'] as String,
    ticketTierId: json['ticket_tier_id'] as String?,
    status: RegistrationStatus.values.firstWhere((e) => e.name == json['status']),
    quantity: json['quantity'] as int? ?? 1,
    formResponses: json['form_responses'] is Map<String, dynamic>
        ? json['form_responses'] as Map<String, dynamic>
        : {},
    subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : 0,
    discountAmount: json['discount_amount'] != null ? (json['discount_amount'] as num).toDouble() : 0,
    totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : 0,
    promoCodeId: json['promo_code_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Registration copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? ticketTierId,
    RegistrationStatus? status,
    int? quantity,
    Map<String, dynamic>? formResponses,
    double? subtotal,
    double? discountAmount,
    double? totalAmount,
    String? promoCodeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Registration(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    userId: userId ?? this.userId,
    ticketTierId: ticketTierId ?? this.ticketTierId,
    status: status ?? this.status,
    quantity: quantity ?? this.quantity,
    formResponses: formResponses ?? this.formResponses,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    promoCodeId: promoCodeId ?? this.promoCodeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum PortfolioLayout { STACKED, GRID }

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? organization;
  final String? phone;
  final String? website;
  final String? linkedinUrl;
  final String? twitterUrl;
  final String? githubUrl;
  final String qrCode;
  final bool portfolioIsPublic;
  final PortfolioLayout portfolioLayout;
  final String? portfolioAccentColor;
  final List<String> portfolioSections;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.organization,
    this.phone,
    this.website,
    this.linkedinUrl,
    this.twitterUrl,
    this.githubUrl,
    required this.qrCode,
    this.portfolioIsPublic = false,
    this.portfolioLayout = PortfolioLayout.STACKED,
    this.portfolioAccentColor,
    this.portfolioSections = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate profile completeness (0-100)
  int get completeness {
    int filledCount = 0;
    const int totalFields = 5;
    if (fullName != null && fullName!.isNotEmpty) filledCount++;
    if (organization != null && organization!.isNotEmpty) filledCount++;
    if (phone != null && phone!.isNotEmpty) filledCount++;
    if (bio != null && bio!.isNotEmpty) filledCount++;
    if (website != null && website!.isNotEmpty) filledCount++;
    return ((filledCount / totalFields) * 100).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'organization': organization,
    'phone': phone,
    'website': website,
    'linkedin_url': linkedinUrl,
    'twitter_url': twitterUrl,
    'github_url': githubUrl,
    'qr_code': qrCode,
    'portfolio_is_public': portfolioIsPublic,
    'portfolio_layout': portfolioLayout.name,
    'portfolio_accent_color': portfolioAccentColor,
    'portfolio_sections': portfolioSections,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    bio: json['bio'] as String?,
    organization: json['organization'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    linkedinUrl: json['linkedin_url'] as String?,
    twitterUrl: json['twitter_url'] as String?,
    githubUrl: json['github_url'] as String?,
    qrCode: json['qr_code'] as String,
    portfolioIsPublic: json['portfolio_is_public'] as bool? ?? false,
    portfolioLayout: json['portfolio_layout'] != null
        ? PortfolioLayout.values.firstWhere(
            (e) => e.name == json['portfolio_layout'],
            orElse: () => PortfolioLayout.STACKED,
          )
        : PortfolioLayout.STACKED,
    portfolioAccentColor: json['portfolio_accent_color'] as String?,
    portfolioSections: json['portfolio_sections'] != null
        ? List<String>.from(json['portfolio_sections'] as List)
        : [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? organization,
    String? phone,
    String? website,
    String? linkedinUrl,
    String? twitterUrl,
    String? githubUrl,
    String? qrCode,
    bool? portfolioIsPublic,
    PortfolioLayout? portfolioLayout,
    String? portfolioAccentColor,
    List<String>? portfolioSections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    bio: bio ?? this.bio,
    organization: organization ?? this.organization,
    phone: phone ?? this.phone,
    website: website ?? this.website,
    linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    twitterUrl: twitterUrl ?? this.twitterUrl,
    githubUrl: githubUrl ?? this.githubUrl,
    qrCode: qrCode ?? this.qrCode,
    portfolioIsPublic: portfolioIsPublic ?? this.portfolioIsPublic,
    portfolioLayout: portfolioLayout ?? this.portfolioLayout,
    portfolioAccentColor: portfolioAccentColor ?? this.portfolioAccentColor,
    portfolioSections: portfolioSections ?? this.portfolioSections,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class NotificationPreferences {
  final String userId;
  final bool workspaceEnabled;
  final bool eventEnabled;
  final bool marketplaceEnabled;
  final bool organizationEnabled;
  final bool systemEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationPreferences({
    required this.userId,
    this.workspaceEnabled = true,
    this.eventEnabled = true,
    this.marketplaceEnabled = true,
    this.organizationEnabled = true,
    this.systemEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'workspace_enabled': workspaceEnabled,
    'event_enabled': eventEnabled,
    'marketplace_enabled': marketplaceEnabled,
    'organization_enabled': organizationEnabled,
    'system_enabled': systemEnabled,
    'sound_enabled': soundEnabled,
    'vibration_enabled': vibrationEnabled,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => NotificationPreferences(
    userId: json['user_id'] as String,
    workspaceEnabled: json['workspace_enabled'] as bool? ?? true,
    eventEnabled: json['event_enabled'] as bool? ?? true,
    marketplaceEnabled: json['marketplace_enabled'] as bool? ?? true,
    organizationEnabled: json['organization_enabled'] as bool? ?? true,
    systemEnabled: json['system_enabled'] as bool? ?? true,
    soundEnabled: json['sound_enabled'] as bool? ?? true,
    vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
  );

  NotificationPreferences copyWith({
    String? userId,
    bool? workspaceEnabled,
    bool? eventEnabled,
    bool? marketplaceEnabled,
    bool? organizationEnabled,
    bool? systemEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) => NotificationPreferences(
    userId: userId ?? this.userId,
    workspaceEnabled: workspaceEnabled ?? this.workspaceEnabled,
    eventEnabled: eventEnabled ?? this.eventEnabled,
    marketplaceEnabled: marketplaceEnabled ?? this.marketplaceEnabled,
    organizationEnabled: organizationEnabled ?? this.organizationEnabled,
    systemEnabled: systemEnabled ?? this.systemEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );
}

// ==========================
// UTILITIES
// ==========================

extension EventCategoryX on EventCategory {
  String get displayName => switch (this) {
    EventCategory.HACKATHON => 'Hackathon',
    EventCategory.WORKSHOP => 'Workshop',
    EventCategory.CONFERENCE => 'Conference',
    EventCategory.MEETUP => 'Meetup',
    EventCategory.WEBINAR => 'Webinar',
    EventCategory.SEMINAR => 'Seminar',
    EventCategory.BOOTCAMP => 'Bootcamp',
    EventCategory.STARTUP_PITCH => 'Startup Pitch',
    EventCategory.COMPETITION => 'Competition',
    EventCategory.CULTURAL_FEST => 'Cultural Fest',
    EventCategory.SPORTS_EVENT => 'Sports Event',
    EventCategory.CAREER_FAIR => 'Career Fair',
    EventCategory.NETWORKING => 'Networking',
    EventCategory.PRODUCT_LAUNCH => 'Product Launch',
    EventCategory.SUMMIT => 'Summit',
    EventCategory.DEMO_DAY => 'Demo Day',
    EventCategory.OTHER => 'Other',
  };
}

// ==========================
// CHAT MODELS
// ==========================

/// Chat channel types
enum ChannelType { GENERAL, ANNOUNCEMENT, ROLE_BASED, TASK_SPECIFIC }

extension ChannelTypeX on ChannelType {
  String get label => switch (this) {
        ChannelType.ANNOUNCEMENT => 'ANNOUNCEMENTS',
        ChannelType.GENERAL => 'GENERAL',
        ChannelType.ROLE_BASED => 'ROLE_BASED',
        ChannelType.TASK_SPECIFIC => 'TASK_SPECIFIC',
      };
}

class WorkspaceChannel {
  final String id;
  final String workspaceId;
  final String name;
  final ChannelType type;
  final String? description;
  final List<dynamic> members; // keep dynamic to match Supabase JSON arrays
  final bool isPrivate;

  const WorkspaceChannel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.type,
    this.description,
    this.members = const [],
    this.isPrivate = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspace_id': workspaceId,
        'name': name,
        'type': type.name,
        'description': description,
        'members': members,
        'is_private': isPrivate,
      };

  factory WorkspaceChannel.fromJson(Map<String, dynamic> json) => WorkspaceChannel(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String,
        name: json['name'] as String,
        type: ChannelType.values.firstWhere(
          (e) => e.name == (json['type'] as String?)?.toUpperCase(),
          orElse: () => ChannelType.GENERAL,
        ),
        description: json['description'] as String?,
        members: json['members'] is List ? List<dynamic>.from(json['members'] as List) : const [],
        isPrivate: json['is_private'] as bool? ?? false,
      );
}

class MessageAttachment {
  final String filename;
  final String url;
  final int size;

  const MessageAttachment({required this.filename, required this.url, required this.size});

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'url': url,
        'size': size,
      };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => MessageAttachment(
        filename: json['filename'] as String,
        url: json['url'] as String,
        size: json['size'] is int ? json['size'] as int : (json['size'] as num?)?.toInt() ?? 0,
      );
}

class Message {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final List<MessageAttachment> attachments;
  final DateTime sentAt;
  final DateTime? editedAt;

  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.attachments = const [],
    required this.sentAt,
    this.editedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'content': content,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'sent_at': sentAt.toIso8601String(),
        'edited_at': editedAt?.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    final atts = <MessageAttachment>[];
    final rawAtts = json['attachments'];
    if (rawAtts is List) {
      for (final a in rawAtts) {
        if (a is Map) atts.add(MessageAttachment.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return Message(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderAvatar: json['sender_avatar'] as String?,
      content: json['content'] as String? ?? '',
      attachments: atts,
      sentAt: DateTime.parse(json['sent_at'] as String),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
    );
  }
}

/// Direct message thread summary
class DMThread {
  final String channelId;
  final String partnerUserId;
  final String partnerName;
  final String? partnerAvatar;
  final Message? lastMessage;
  final DateTime updatedAt;

  const DMThread({
    required this.channelId,
    required this.partnerUserId,
    required this.partnerName,
    this.partnerAvatar,
    required this.lastMessage,
    required this.updatedAt,
  });
}

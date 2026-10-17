import '../models/property_model.dart';

/// Kinds of non-property content that can be woven into the feed.
/// Add new values here as you introduce more insert types (ads, banners,
/// promoted agents, etc.) — the builder and widget switch on this enum,
/// so adding a type is a matter of extending it in one place.
enum InsertType {
  videoReel,
}

/// A single entry in the rendered feed — either a real property, or a
/// non-property insert (e.g. the video reel card).
abstract class FeedEntry {
  const FeedEntry();
}

class PropertyEntry extends FeedEntry {
  final PropertyModel property;
  const PropertyEntry(this.property);
}

class InsertEntry extends FeedEntry {
  final InsertType type;
  const InsertEntry(this.type);
}

/// Describes when/whether a given insert type should appear.
///
/// [afterItemCount] places the insert after that many property items have
/// been laid out (e.g. 4 => appears after the 4th property, as the 5th
/// card, without removing the 4th property from the feed).
///
/// [isEligible] is checked against the *full* property list before
/// inserting — e.g. don't show a "Videos" card if nothing in the feed is
/// actually a video.
class FeedInsertRule {
  final InsertType type;
  final int afterItemCount;
  final bool Function(List<PropertyModel> allProperties) isEligible;

  const FeedInsertRule({
    required this.type,
    required this.afterItemCount,
    required this.isEligible,
  });
}

bool _hasVideoContent(List<PropertyModel> properties) =>
    properties.any((p) => p.isVideo == 1);

/// Default insert rules for the Recommended feed. Extend this list (don't
/// replace the mechanism) when you add a new insert type — e.g.:
///
/// ```dart
/// const defaultFeedInserts = [
///   videoReelInsertRule,
///   FeedInsertRule(
///     type: InsertType.sponsoredAgent,
///     afterItemCount: 10,
///     isEligible: (props) => someCondition,
///   ),
/// ];
/// ```
const FeedInsertRule videoReelInsertRule = FeedInsertRule(
  type: InsertType.videoReel,
  afterItemCount: 4,
  isEligible: _hasVideoContent,
);

const List<FeedInsertRule> defaultFeedInserts = [videoReelInsertRule];

/// Builds the ordered list actually rendered by the feed's ListView,
/// weaving eligible inserts in between properties without ever dropping
/// a property to make room for one.
List<FeedEntry> buildRecommendedFeed(
  List<PropertyModel> properties, {
  List<FeedInsertRule> inserts = defaultFeedInserts,
}) {
  // Only consider rules that can actually fire: there must be enough
  // properties to reach the requested position, and the eligibility
  // check (e.g. "are there any videos at all?") must pass.
  final Map<int, List<InsertType>> insertsByPosition = {};
  for (final rule in inserts) {
    if (rule.afterItemCount <= properties.length &&
        rule.isEligible(properties)) {
      insertsByPosition
          .putIfAbsent(rule.afterItemCount, () => [])
          .add(rule.type);
    }
  }

  final feed = <FeedEntry>[];
  for (var i = 0; i < properties.length; i++) {
    feed.add(PropertyEntry(properties[i]));
    final dueHere = insertsByPosition[i + 1];
    if (dueHere != null) {
      for (final type in dueHere) {
        feed.add(InsertEntry(type));
      }
    }
  }
  return feed;
}

/// Convenience getter for widgets (e.g. the video reel card) that should
/// only ever see the properties that are actually videos.
extension VideoPropertiesX on List<PropertyModel> {
  List<PropertyModel> get videoOnly => where((p) => p.isVideo == 1).toList();
}

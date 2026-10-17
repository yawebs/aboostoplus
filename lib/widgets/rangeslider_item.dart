import 'package:cupertino_range_slider_improved/cupertino_range_slider.dart';
import 'package:flutter/cupertino.dart';

class RangeSliderItem extends StatefulWidget {
  final String title;
  final int initialMinValue;
  final int initialMaxValue;
  final ValueChanged<int> onMinValueChanged;
  final ValueChanged<int> onMaxValueChanged;

  const RangeSliderItem(
      {Key? key,
      required this.title,
      required this.initialMinValue,
      required this.initialMaxValue,
      required this.onMinValueChanged,
      required this.onMaxValueChanged})
      : super(key: key);

  @override
  _RangeSliderItemState createState() => _RangeSliderItemState();
}

class _RangeSliderItemState extends State<RangeSliderItem> {
  late int minValue;
  late int maxValue;

  @override
  void initState() {
    super.initState();
    minValue = widget.initialMinValue;
    maxValue = widget.initialMaxValue;
  }

  @override
  Widget build(BuildContext context) {
    return FilterItemHolder(
      title: widget.title,
      value: '₦$minValue\000-$maxValue\00',
      child: CupertinoRangeSlider(
        minValue: minValue.roundToDouble(),
        maxValue: maxValue.roundToDouble(),
        min: 1.0,
        max: 100.0,
        onMinChanged: (minVal) {
          setState(() {
            minValue = minVal.round();
            widget.onMinValueChanged(minValue);
          });
        },
        onMaxChanged: (maxVal) {
          setState(() {
            maxValue = maxVal.round();
            widget.onMaxValueChanged(maxValue);
          });
        },
      ),
    );
  }
}

class FilterItemHolder extends StatelessWidget {
  final String title;
  final String value;
  final Widget? child;

  FilterItemHolder({Key? key, required this.title, this.value = '', this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.fromLTRB(0.0, 24.0, 0.0, 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: titleTextStyle,
                ),
              ),
              Text(
                value,
                style: titleTextStyle,
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
          child: Container(
            height: 47.0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(),
              child: child,
            ),
          ),
        )
      ],
    );
  }

  final titleTextStyle = const TextStyle(
    color: Color(0xFF000000),
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
  );
}

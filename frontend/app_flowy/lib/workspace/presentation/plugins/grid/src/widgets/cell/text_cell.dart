import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  String? placeholder;

  GridTextCellStyle({
    this.placeholder,
  });
}

class GridTextCell extends GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final GridTextCellStyle? cellStyle;
  GridTextCell({
    required this.cellContextBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  State<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends State<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  VoidCallback? _focusListener;
  Timer? _delayOperation;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build();
    _cellBloc = getIt<TextCellBloc>(param1: cellContext);
    _cellBloc.add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus.value = _focusNode.hasFocus;
      focusChanged();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _listenCellRequestFocus(context);

    return BlocProvider.value(
      value: _cellBloc,
      child: BlocConsumer<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) => focusChanged(),
            onEditingComplete: () => _focusNode.unfocus(),
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: widget.cellStyle?.placeholder,
              isDense: true,
            ),
          );
        },
      ),
    );
  }

  void _listenCellRequestFocus(BuildContext context) {
    if (_focusListener != null) {
      widget.requestFocus.removeListener(_focusListener!);
    }

    focusListener() {
      if (_focusNode.hasFocus == false && _focusNode.canRequestFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    }

    _focusListener = focusListener;
    widget.requestFocus.addListener(focusListener);
  }

  @override
  Future<void> dispose() async {
    if (_focusListener != null) {
      widget.requestFocus.removeListener(_focusListener!);
    }
    _delayOperation?.cancel();
    _cellBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false && _controller.text != _cellBloc.state.content) {
          _cellBloc.add(TextCellEvent.updateText(_controller.text));
        }
      });
    }
  }
}
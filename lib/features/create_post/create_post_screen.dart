import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/media_picker_service.dart';
import '../../core/utils/feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../data/dummy_data/dummy_data.dart';
import '../../models/post_model.dart';
import '../../state/app_state.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _caption = TextEditingController();
  String? _image;
  String _location = AppDummyData.locations.first;
  bool _busy = false;

  static const _hashtags = [
    '#instagram',
    '#flutter',
    '#photography',
    '#travel',
    '#love',
    '#daily',
  ];

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    final path = await MediaPickerService.pickImage();
    if (path == null) {
      if (mounted) {
        FeedbackUtils.snack(
          context,
          'Gallery unavailable or permission denied. Choose a sample image instead.',
          isError: true,
        );
      }
      return;
    }
    setState(() => _image = path);
  }

  Future<void> _publish() async {
    final me = ref.read(appProvider).currentUser;
    if (me == null) return;
    if (_image == null) {
      FeedbackUtils.snack(context, 'Please select an image first', isError: true);
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    final post = PostModel(
      id: 'p_local_${DateTime.now().microsecondsSinceEpoch}',
      userId: me.id,
      caption: _caption.text.trim(),
      imageUrls: [_image!],
      location: _location,
      createdAt: DateTime.now(),
      likeCount: 0,
      isCreatedByUser: true,
    );
    ref.read(appProvider.notifier).addPost(post);
    Navigator.of(context).pop(true);
    FeedbackUtils.success();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Create post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _image == null || _busy ? null : _publish,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Share'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: .6)),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 54, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('Choose a photo to share',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Open gallery'),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(url: _image!),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _image = null),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppDummyData.sampleImages.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: _pickGallery,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_camera_outlined),
                    ),
                  );
                }
                final url = AppDummyData.sampleImages[index - 1];
                return GestureDetector(
                  onTap: () => setState(() => _image = url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: _image == url
                            ? Border.all(color: AppColors.instagramBlue, width: 3)
                            : null,
                      ),
                      child: AppImage(url: url, width: 58, height: 58),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _caption,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Write a caption and tell the story...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text('Add hashtags',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in _hashtags)
                ActionChip(
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    final current = _caption.text.trim();
                    _caption.text =
                        current.isEmpty ? '$tag ' : '$current $tag ';
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            items: [
              for (final location in AppDummyData.locations)
                DropdownMenuItem(value: location, child: Text(location)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _location = value);
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _image == null || _busy ? null : _publish,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Publish post'),
          ),
          const SizedBox(height: 18),
          Text(
            'Your post will appear in the home feed and on your profile. Everything is stored locally on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

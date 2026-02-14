import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 스티커팩 관리 화면 (관리자용)
/// 
/// 기능:
/// - 스티커팩 목록 조회
/// - 스티커 개별 업로드
/// - 스티커 개별 삭제
/// - 새 스티커팩 생성
class StickerPackManagementScreen extends StatefulWidget {
  const StickerPackManagementScreen({super.key});

  @override
  State<StickerPackManagementScreen> createState() => _StickerPackManagementScreenState();
}

class _StickerPackManagementScreenState extends State<StickerPackManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스티커팩 관리'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _showCreatePackDialog,
            tooltip: '새 스티커팩 생성',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('sticker_packs')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                  const SizedBox(height: 16),
                  Text('오류: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_emoticon, color: Colors.grey[400], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '스티커팩이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreatePackDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('새 스티커팩 만들기'),
                  ),
                ],
              ),
            );
          }

          final packs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              final data = pack.data() as Map<String, dynamic>;
              final packName = data['pack_name'] as String? ?? '이름 없음';
              final stickers = data['stickers'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ExpansionTile(
                  leading: Icon(
                    Icons.collections,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  title: Text(
                    packName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${stickers.length}개의 스티커'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeletePack(pack.id, packName),
                    tooltip: '스티커팩 삭제',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 스티커 추가 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _addStickerToPack(pack.id, packName),
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('스티커 추가'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          // 스티커 그리드
                          if (stickers.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  '스티커가 없습니다\n위 버튼을 눌러 추가하세요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: stickers.length,
                              itemBuilder: (context, stickerIndex) {
                                final sticker = stickers[stickerIndex] as Map<String, dynamic>;
                                final imageUrl = sticker['image_url'] as String;
                                final stickerName = sticker['sticker_name'] as String? ?? '스티커';

                                return Stack(
                                  children: [
                                    // 스티커 이미지
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // 삭제 버튼
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _confirmDeleteSticker(
                                          pack.id,
                                          packName,
                                          stickerIndex,
                                          stickerName,
                                          imageUrl,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      // 업로드 진행 상태 표시
      bottomSheet: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '업로드 중... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            )
          : null,
    );
  }

  /// 새 스티커팩 생성 다이얼로그
  void _showCreatePackDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 스티커팩 만들기'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '스티커팩 이름',
            hintText: '예: 동물 친구들',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('스티커팩 이름을 입력하세요')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _firestore.collection('sticker_packs').add({
                  'pack_name': name,
                  'stickers': [],
                  'created_at': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('스티커팩 "$name" 생성 완료!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  /// 스티커 추가
  Future<void> _addStickerToPack(String packId, String packName) async {
    try {
      // 1. 이미지 선택
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // 2. 스티커 이름 입력
      final stickerName = await _showStickerNameDialog();
      if (stickerName == null || stickerName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('스티커 이름을 입력하세요')),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // 3. Firebase Storage에 업로드
      final fileName = 'stickers/${packId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = _storage.ref().child(fileName);
      
      final uploadTask = storageRef.putFile(File(image.path));
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // 4. Firestore에 스티커 정보 추가
      await _firestore.collection('sticker_packs').doc(packId).update({
        'stickers': FieldValue.arrayUnion([
          {
            'sticker_name': stickerName,
            'image_url': downloadUrl,
          }
        ])
      });

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$stickerName" 스티커 추가 완료!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }

      if (kDebugMode) {
        print('스티커 추가 실패: $e');
      }
    }
  }

  /// 스티커 이름 입력 다이얼로그
  Future<String?> _showStickerNameDialog() async {
    final nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스티커 이름'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '스티커 이름',
            hintText: '예: 웃는 고양이',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스티커 삭제 확인
  void _confirmDeleteSticker(
    String packId,
    String packName,
    int stickerIndex,
    String stickerName,
    String imageUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스티커 삭제'),
        content: Text('스티커 "$stickerName"를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSticker(packId, packName, stickerIndex, stickerName, imageUrl);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 스티커 삭제
  Future<void> _deleteSticker(
    String packId,
    String packName,
    int stickerIndex,
    String stickerName,
    String imageUrl,
  ) async {
    try {
      // 1. Firestore에서 스티커 정보 가져오기
      final packDoc = await _firestore.collection('sticker_packs').doc(packId).get();
      final data = packDoc.data() as Map<String, dynamic>;
      final stickers = List<Map<String, dynamic>>.from(data['stickers'] as List);

      // 2. 해당 스티커 제거
      stickers.removeAt(stickerIndex);

      // 3. Firestore 업데이트
      await _firestore.collection('sticker_packs').doc(packId).update({
        'stickers': stickers,
      });

      // 4. Firebase Storage에서 이미지 삭제 (선택사항)
      try {
        final storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        if (kDebugMode) {
          print('Storage 삭제 실패 (무시 가능): $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$stickerName" 스티커 삭제 완료')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }

      if (kDebugMode) {
        print('스티커 삭제 실패: $e');
      }
    }
  }

  /// 스티커팩 삭제 확인
  void _confirmDeletePack(String packId, String packName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스티커팩 삭제'),
        content: Text('스티커팩 "$packName"를 삭제하시겠습니까?\n모든 스티커가 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePack(packId, packName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 스티커팩 삭제
  Future<void> _deletePack(String packId, String packName) async {
    try {
      await _firestore.collection('sticker_packs').doc(packId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스티커팩 "$packName" 삭제 완료')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }

      if (kDebugMode) {
        print('스티커팩 삭제 실패: $e');
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// 관리자 스티커 관리 화면
/// - 스티커팩 생성/수정/삭제
/// - 투명 배경 GIF 업로드
/// - Firebase Storage + Firestore 연동
class AdminStickerScreen extends StatefulWidget {
  const AdminStickerScreen({super.key});

  @override
  State<AdminStickerScreen> createState() => _AdminStickerScreenState();
}

class _AdminStickerScreenState extends State<AdminStickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packNameController = TextEditingController();
  final _packIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _selectedStickers = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  @override
  void dispose() {
    _packNameController.dispose();
    _packIdController.dispose();
    super.dispose();
  }

  /// GIF 파일 선택 (여러 개)
  Future<void> _pickGifFiles() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isEmpty) {
        _showSnackBar('이미지를 선택하지 않았습니다.', isError: true);
        return;
      }

      // GIF 파일만 필터링
      final gifFiles = images.where((file) => 
        file.path.toLowerCase().endsWith('.gif') ||
        file.path.toLowerCase().endsWith('.png') ||
        file.path.toLowerCase().endsWith('.webp')
      ).toList();

      if (gifFiles.isEmpty) {
        _showSnackBar('GIF, PNG, WebP 파일만 선택 가능합니다.', isError: true);
        return;
      }

      setState(() {
        for (var file in gifFiles) {
          _selectedStickers.add({
            'file': file,
            'name': file.name.replaceAll(RegExp(r'\.(gif|png|webp)$'), ''),
            'order': _selectedStickers.length,
          });
        }
      });

      _showSnackBar('${gifFiles.length}개 스티커 선택 완료!');
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [스티커 선택] 실패: $e');
      }
      _showSnackBar('스티커 선택 실패: $e', isError: true);
    }
  }

  /// Firebase Storage에 스티커 업로드
  Future<String?> _uploadStickerToStorage(XFile file, String packId, int index) async {
    try {
      final fileName = 'sticker_${index.toString().padLeft(3, '0')}.${file.name.split('.').last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('stickers/$packId/$fileName');

      final bytes = await file.readAsBytes();
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/gif'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ [스티커 업로드] $fileName → $downloadUrl');
      }
      
      return downloadUrl;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [스티커 업로드] 실패: $e');
      }
      return null;
    }
  }

  /// Firestore에 스티커팩 메타데이터 저장
  Future<void> _saveStickerPackToFirestore(String packId, String packName, List<Map<String, dynamic>> stickers) async {
    try {
      final stickerPackData = {
        'pack_id': packId,
        'pack_name': packName,
        'is_default': false,
        'created_at': FieldValue.serverTimestamp(),
        'sticker_count': stickers.length,
        'stickers': stickers.map((s) => {
          'sticker_id': '${packId}_${s['order']}',
          'sticker_name': s['name'],
          'image_url': s['url'],
          'order': s['order'],
          'file_name': s['file_name'],
        }).toList(),
      };

      await FirebaseFirestore.instance
          .collection('sticker_packs')
          .doc(packId)
          .set(stickerPackData);

      if (kDebugMode) {
        debugPrint('✅ [Firestore] 스티커팩 저장 완료: $packId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Firestore] 저장 실패: $e');
      }
      rethrow;
    }
  }

  /// 스티커팩 업로드 프로세스
  Future<void> _uploadStickerPack() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStickers.isEmpty) {
      _showSnackBar('스티커를 선택해주세요!', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final packId = _packIdController.text.trim();
      final packName = _packNameController.text.trim();
      
      final uploadedStickers = <Map<String, dynamic>>[];

      // 각 스티커 업로드
      for (int i = 0; i < _selectedStickers.length; i++) {
        final sticker = _selectedStickers[i];
        final file = sticker['file'] as XFile;
        
        final downloadUrl = await _uploadStickerToStorage(file, packId, i + 1);
        
        if (downloadUrl != null) {
          uploadedStickers.add({
            'name': sticker['name'],
            'url': downloadUrl,
            'order': i,
            'file_name': file.name,
          });
        }
      }

      // Firestore에 저장
      await _saveStickerPackToFirestore(packId, packName, uploadedStickers);

      _showSnackBar('✅ 스티커팩 업로드 완료! (${uploadedStickers.length}개)');
      
      // 초기화
      setState(() {
        _selectedStickers.clear();
        _packNameController.clear();
        _packIdController.clear();
      });

    } catch (e) {
      _showSnackBar('업로드 실패: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// 스낵바 표시
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  /// 스티커 삭제
  void _removeSticker(int index) {
    setState(() {
      _selectedStickers.removeAt(index);
      // 순서 재조정
      for (int i = 0; i < _selectedStickers.length; i++) {
        _selectedStickers[i]['order'] = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스티커 관리자'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 안내 카드
              _buildGuideCard(),
              const SizedBox(height: 24),

              /// 스티커팩 정보 입력
              _buildPackInfoSection(),
              const SizedBox(height: 24),

              /// 스티커 선택 버튼
              _buildSelectStickerButton(),
              const SizedBox(height: 16),

              /// 선택된 스티커 미리보기
              if (_selectedStickers.isNotEmpty) ...[
                _buildStickerPreviewGrid(),
                const SizedBox(height: 24),
              ],

              /// 업로드 버튼
              _buildUploadButton(),

              /// 업로드 진행 상황
              if (_isUploading) ...[
                const SizedBox(height: 16),
                _buildUploadProgress(),
              ],

              const SizedBox(height: 24),

              /// 기존 스티커팩 목록
              _buildExistingStickerPacks(),
            ],
          ),
        ),
      ),
    );
  }

  /// 안내 카드
  Widget _buildGuideCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  '투명 배경 GIF 제작 가이드',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideItem('1️⃣', 'Canva (추천)', 'https://canva.com'),
            _buildGuideItem('2️⃣', 'Ezgif', 'https://ezgif.com'),
            _buildGuideItem('3️⃣', 'LottieFiles', 'https://lottiefiles.com'),
            const SizedBox(height: 8),
            Text(
              '✅ 권장: 400x400px, 500KB 이하, GIF/PNG/WebP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String emoji, String name, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '$name: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                color: Colors.blue[700],
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 스티커팩 정보 입력 섹션
  Widget _buildPackInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '스티커팩 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _packNameController,
          decoration: const InputDecoration(
            labelText: '스티커팩 이름',
            hintText: '예: 귀여운 고양이',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '스티커팩 이름을 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _packIdController,
          decoration: const InputDecoration(
            labelText: '스티커팩 ID (영문, 숫자, _ 만)',
            hintText: '예: cute_cat_01',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '스티커팩 ID를 입력해주세요';
            }
            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value.trim())) {
              return '영문 소문자, 숫자, _만 사용 가능합니다';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 스티커 선택 버튼
  Widget _buildSelectStickerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _pickGifFiles,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(
          _selectedStickers.isEmpty 
              ? 'GIF/PNG/WebP 파일 선택'
              : '스티커 추가 (현재 ${_selectedStickers.length}개)',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 선택된 스티커 미리보기 그리드
  Widget _buildStickerPreviewGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 스티커 (${_selectedStickers.length}개)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _selectedStickers.length,
          itemBuilder: (context, index) {
            final sticker = _selectedStickers[index];
            final file = sticker['file'] as XFile;
            
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: kIsWeb
                        ? Image.network(
                            file.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.file(
                            File(file.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeSticker(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
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
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sticker['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 업로드 버튼
  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isUploading || _selectedStickers.isEmpty) ? null : _uploadStickerPack,
        icon: _isUploading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(
          _isUploading ? '업로드 중...' : '스티커팩 업로드',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 업로드 진행 상황
  Widget _buildUploadProgress() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 8),
        Text(
          '업로드 중: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// 기존 스티커팩 목록
  Widget _buildExistingStickerPacks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          '등록된 스티커팩',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sticker_packs')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('오류: ${snapshot.error}');
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('등록된 스티커팩이 없습니다.'),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text('${data['sticker_count'] ?? 0}'),
                    ),
                    title: Text(data['pack_name'] ?? '이름 없음'),
                    subtitle: Text('ID: ${data['pack_id'] ?? 'N/A'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStickerPack(doc.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// 스티커팩 삭제
  Future<void> _deleteStickerPack(String packId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스티커팩 삭제'),
        content: const Text('정말로 이 스티커팩을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('sticker_packs')
          .doc(packId)
          .delete();
      
      _showSnackBar('스티커팩 삭제 완료');
    } catch (e) {
      _showSnackBar('삭제 실패: $e', isError: true);
    }
  }
}

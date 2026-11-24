import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/model/reading_record.dart';
import 'book_cover.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, required this.onTap});
  final ReadingRecord record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(url: record.coverUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        record.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM • HH:mm',
                          'pt_BR',
                        ).format(record.eventAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (!record.synced)
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 16,
                          semanticLabel: 'Alteração aguardando sincronização',
                        ),
                      if (record.hasLocation)
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          semanticLabel: 'Localização registrada',
                        ),
                    ],
                  ),
                  if (record.totalPages > 0) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (record.pages / record.totalPages).clamp(0, 1),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.pages} de ${record.totalPages} páginas',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

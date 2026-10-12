import 'package:flutter/material.dart';
import '../widgets/campaign_form.dart';

class EditCampaignScreen extends StatelessWidget {
  const EditCampaignScreen({super.key});
  @override
  Widget build(BuildContext context) => const CampaignForm(edit: true);
}

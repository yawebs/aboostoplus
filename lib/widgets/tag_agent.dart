import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/services/providers/tagged_users_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagAgentWidget extends StatefulWidget {
  const TagAgentWidget({Key? key}) : super(key: key);

  @override
  State<TagAgentWidget> createState() => _TagAgentWidgetState();
}

class _TagAgentWidgetState extends State<TagAgentWidget> {
  TextEditingController searchController = TextEditingController();
  List<UserModel> agents = [];
  List<UserModel> searchedAgentsList = [];
  List<UserModel> selectedAgents = [];
  List<bool> checked = [];
  bool _isLoading = false;
  getSuggestedAgents() async {
    setState(() {
      _isLoading = true;
    });
    List<UserModel> sAgents = await DbServices.getAgents();
    setState(() {
      agents = sAgents;
      checked = List.filled(agents.length, false);
      _isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSuggestedAgents();
  }

  @override
  Widget build(BuildContext context) {
    bool showSheet = MediaQuery.of(context).viewInsets.bottom == 0.0;
    return Scaffold(
      bottomSheet: showSheet ? continueButton() : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView(children: [
          h10(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (selectedAgents.isNotEmpty) {
                    Provider.of<TaggedAgentsProvider>(context, listen: false)
                        .addTaggedAgent(selectedAgents);
                  }
                  goBack(context);
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: context.palette.ink,
                ),
              ),
              Text(
                'Tag Agents',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                width: 25,
                height: 25,
                child: ClipOval(
                  child: Image.asset(
                    imageRounte(name: avatarImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          h10(),
          h10(),
          Container(
            decoration: BoxDecoration(
              borderRadius: appRadius(20.0),
              color: context.palette.paperAlt,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) async {
                if (searchController.text.isNotEmpty) {
                  List<UserModel> searchedAgents =
                      await DbServices.searchAgents(searchController.text);
                  debugPrint('Check search agent ${searchedAgents.length}');
                  setState(() {
                    searchedAgentsList = searchedAgents;
                  });
                }
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Agent',
                border: InputBorder.none,
              ),
            ),
          ),
          h10(),
          h10(),
          searchedAgentsList.isEmpty
              ? const Text(
                  'Suggested Agents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                )
              : const SizedBox.shrink(),
          h10(),
          _isLoading
              ? Container(
                  height: 200,
                  child: appSearchLoader(context.palette.accent, 30.0),
                )
              : displayUsers()
        ]),
      ),
    );
  }

  List<UserModel> getData(List<UserModel> agents, List<UserModel> dsearchList) {
    return dsearchList.isEmpty ? agents : dsearchList;
  }

  displayUsers() {
    return Card(
      child: ListView.builder(
          itemCount: getData(agents, searchedAgentsList).length,
          shrinkWrap: true,
          primary: false,
          itemBuilder: (ctx, index) {
            UserModel agent = getData(agents, searchedAgentsList)[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 5.0,
                vertical: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        child: ClipOval(
                          child: Image.asset(
                            imageRounte(name: avatarImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          showDisplayName(agent),
                          style: TextStyle(
                            fontSize: 16,
                            color: context.palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Checkbox(
                      value: checked[index],
                      onChanged: (value) {
                        selectAgent(index, value);
                      })
                ],
              ),
            );
          }),
    );
  }

  continueButton() {
    return GestureDetector(
      onTap: () {
        if (selectedAgents.isNotEmpty) {
          Provider.of<TaggedAgentsProvider>(context, listen: false)
              .addTaggedAgent(selectedAgents);
          goBack(context);
        }
      },
      child: Container(
        height: 45,
        width: width(context),
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration:
            BoxDecoration(color: context.palette.primaryFill, borderRadius: appRadius(10.0)),
        child: Center(
          child: Text(
            'Continue',
            style: tStyleWhite,
          ),
        ),
      ),
    );
  }

  selectAgent(index, value) {
    setState(() {
      checked[index] = value!;
    });
    if (value == true) {
      setState(() {
        selectedAgents.add(agents[index]);
      });
    } else {
      setState(() {
        selectedAgents.removeWhere((element) => element.id == agents[index].id);
      });
    }
  }
}

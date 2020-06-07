import 'package:flutter/material.dart';
import 'package:todo_yassine/gebruikerPagina.dart';
import 'todoPagina.dart';
import 'chatPagina.dart';
import 'Maps.dart';

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  int _cIndex = 0;
  final List<Widget> _children = [TodoPagina(), MapsPagina(),ChatPagina(), ];
  void _incrementTab(index) {
    if (this.mounted){
    setState(() {
      _cIndex = index;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    //_getData();

    return new Scaffold(
        appBar: new AppBar(
          centerTitle: true,
          title: new Text((() {
            if (this._cIndex == 0) {
              return "Todo";
            } else if (this._cIndex == 1) {
              return "Maps";
            }

            return "Chat";
          })()),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GebruikerPagina()),
                );
              },
            ),
          ],
        ),
        body: _children[_cIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _cIndex,
          selectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.amber,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.view_list), title: new Text('Todo')), BottomNavigationBarItem(
                icon: Icon(Icons.map), title: new Text('Maps')),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat), title: new Text('Chat'))
          ],
          onTap: (index) {
            _incrementTab(index);
          },
        ));
  }
}

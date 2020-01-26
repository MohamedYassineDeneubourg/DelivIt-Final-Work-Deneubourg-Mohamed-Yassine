import 'package:delivit/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductenLijstAankoper extends StatefulWidget {
  @override
  _ProductenLijstAankoperState createState() => _ProductenLijstAankoperState();
}

class _ProductenLijstAankoperState extends State<ProductenLijstAankoper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: White,
      appBar: AppBar(
        backgroundColor: White,
        textTheme: TextTheme(
            title: TextStyle(
                color: Geel,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                fontFamily: "Montserrat")),
        centerTitle: true,
        title: new Text("KIES JE PRODUCTEN"),
      ),
      body: lijst(context),
    );
  }

  String selectedCategory = "Alles";
  returnColor(name) {
    if (name == selectedCategory) {
      return true;
    } else {
      return false;
    }
  }

  Widget lijst(BuildContext context) {
    List<Map> producten = [
      {
        "name": "Coca-Cola",
        "image":
            "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
        "price": "\$45.12",
        "userLiked": true,
        "discount": 2,
      },
      {
        "name": "Coca-Cola",
        "image":
            "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
        "price": "\$45.12",
        "userLiked": true,
        "discount": 2,
      },
      {
        "name": "Coca-Cola",
        "image":
            "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
        "price": "\$45.12",
        "userLiked": true,
        "discount": 2,
      },
      {
        "name": "Coca-Cola",
        "image":
            "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
        "price": "\$45.12",
        "userLiked": true,
        "discount": 2,
      },
      {
        "name": "Coca-Cola",
        "image":
            "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
        "price": "\$45.12",
        "userLiked": true,
        "discount": 2,
      },
    ];

    return Scaffold(
      body: Column(
        children: <Widget>[
          filterCategorieMenu(),
          Expanded(
            child: GridView.count(crossAxisCount: 2, children: <Widget>[
              for (var product in producten)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Center(
                    child: Stack(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0, left: 3),
                          child: Container(
                              width: 175,
                              height: 200,
                              child: RaisedButton(
                                  color: White,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      side: BorderSide(color: GrijsMidden),
                                      borderRadius: BorderRadius.circular(5)),
                                  onPressed: () {},
                                  child: Hero(
                                      transitionOnUserGestures: true,
                                      tag: product["name"],
                                      child: Image.network(product['image'],
                                          width: 100)))),
                        ),
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Text(
                            product["name"],
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Positioned(
                            bottom: 20,
                            right: 10,
                            left: 10,
                            child: Container(
                              padding: EdgeInsets.only(
                                  top: 5, left: 10, right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                  color: Geel.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50)),
                              child: Center(
                                child: Text(product['price'].toString(),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
                              ),
                            )),
                      ],
                    ),
                  ),
                )
            ]),
          ),
        ],
      ),
    );
  }

  Widget filterCategorieMenu() {
    return Padding(
      padding: const EdgeInsets.only(top: 35.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: <Widget>[
                categorieButton('Alles', FontAwesomeIcons.list,
                    onPressed: () {}),
                categorieButton('Drinks', FontAwesomeIcons.wineBottle,
                    onPressed: () {}),
                categorieButton('Creamery', FontAwesomeIcons.iceCream,
                    onPressed: () {}),
                categorieButton('Hot Drinks', FontAwesomeIcons.mugHot,
                    onPressed: () {}),
                categorieButton('Vegetables', FontAwesomeIcons.leaf,
                    onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget categorieButton(String name, IconData icon, {onPressed}) {
    return Container(
      margin: EdgeInsets.only(left: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(bottom: 10),
              width: 65,
              height: 65,
              child: RaisedButton(
                color: returnColor(name) ? Geel : White,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: GrijsDark.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6.0)),
                onPressed: () {
                  setState(() {
                    selectedCategory = name;
                  });
                },
                child: Icon(icon,
                    size: 28, color: returnColor(name) ? White : GrijsDark),
              )),
          Text(name)
        ],
      ),
    );
  }
}

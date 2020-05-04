import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: FirestoreSlideshow(), backgroundColor: Colors.white
          //backgroundColor: Colors.black12,
          ),
    );
  }
}

class FirestoreSlideshow extends StatefulWidget {
  createState() => FirestoreSlideshowState();
}

class FirestoreSlideshowState extends State<FirestoreSlideshow> {
  final PageController crtl = PageController(viewportFraction: 0.9);

  final Firestore db = Firestore.instance;

  int currentPage = 0;

  String activeTag;
  Stream slidesStream;
  List slides;

  @override
  void initState() {
    _queryDb();

    crtl.addListener(() {
      int next = crtl.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: slidesStream,
        initialData: [],
        builder: (context, AsyncSnapshot snap) {
          slides = snap.data.toList();

          return PageView.builder(
              controller: crtl,
              itemCount: slides.length + 1,
              itemBuilder: (context, currentIdx) {
                if (currentIdx == 0) {
                  return _buildTagPage(slides);
                } else if (slides.length >= currentIdx) {
                  bool active = currentIdx == currentPage;
                  return _builderSlidePage(slides[currentIdx - 1], active);
                }
              });
        });
  }

  _builderSlidePage(Map data, bool active) {
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 70 : 150;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 25, right: 30),
      child: Center(
        child: Text(
          data['name'],
          style: TextStyle(
            fontSize: 45,
            fontFamily: 'Lobster',
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(
                  offset: Offset(3.0, 3.0),
                  blurRadius: 4.0,
                  color: Colors.black87),
            ],
          ),
        ),
      ),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
              fit: BoxFit.cover, image: NetworkImage(data['url'])),
          boxShadow: [
            BoxShadow(
                color: Colors.black87,
                blurRadius: blur,
                offset: Offset(offset, offset))
          ]),
    );
  }

  _buildTagPage(List slides) {
    return Container(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Some Places',
                  style: TextStyle(
                      fontSize: 55,
                      color: Colors.deepPurple,
                      fontFamily: 'Lobster'))),
          Container(
              padding: EdgeInsets.only(bottom: 30),
              child: Text('Swipe left',
                  style: TextStyle(fontSize: 16, color: Colors.black54))),
          ...slides.map<Widget>((s) => _buildButton(s['name']))
        ]));
  }

  _buildButton(tag) {
    Color btnColor =
        tag == activeTag ? Colors.deepPurple : Colors.deepPurple[50];
    Color txtColor = tag == activeTag ? Colors.white : Colors.black;
    return FlatButton(
        color: btnColor,
        child: Text(tag,
            style: TextStyle(color: txtColor), textAlign: TextAlign.start),
        onPressed: () => _setIndex(tag));
    /*return SizedBox(
      width: 120,
      child: FlatButton(color: btnColor, child: Text(tag, style: TextStyle(color: txtColor), textAlign: TextAlign.start), onPressed: () => _setIndex(tag))
    );*/
    /*return InkWell(      
      onTap: () => _setIndex(tag),      
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(tag, style: TextStyle(fontSize: 20, color: color))
      ),
    );*/
  }

  _setIndex(tag) {
    int index = slides.indexWhere((s) => s['name'].toString().startsWith(tag));
    setState(() {
      crtl.animateToPage(index + 1,
          duration: Duration(milliseconds: (index + 1) * 500),
          curve: Curves.easeOutSine);
      activeTag = tag;
    });
  }

  _queryDb({String tag = 'favorites'}) {
    // Make a Query
    Query query = db.collection('places');

    // Map the documents to the data payload
    slidesStream =
        query.snapshots().map((list) => list.documents.map((doc) => doc.data));
  }
}

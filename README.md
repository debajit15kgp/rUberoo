# flutter_myuber
![Hi, We are Team rUberoo. 👋 We are from IIT Kharagpur 🚀  🚀 This is our repository for Uber HackTag 2021 ❤️](https://github.com/debajit15kgp/rUberoo/tree/test/images/Intro.gif)
This Repository containes the code and resources to reproduce the work of Team ```rUberoo``` for UberHacktag Grand Finale 2021. 

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## O

Apart from the dataset supplied by the organizers of the shared task, we also used a monolingual English Offensive Language Identification Dataset ([OLID](https://arxiv.org/pdf/1902.09666.pdf)) used in the SemEval-2019 Task 6 (OffensEval). The dataset contains the same labels as our task datasets with the exception of the ```not in intended language``` label. The one-to-one mapping between the labels in OLID and it's large size of 14k tweets makes it suitable for aiding the transfer learning.

## Transformer Architecture

The Transformer Architecture used by us is shown in the figure. We used the pre-trained models realeased by [HuggingFace](https://huggingface.co/transformers/pretrained_models.html).

![Transformer Architecture](https://github.com/kushal2000/Dravidian-Offensive-Language-Identification/blob/master/Transformer_Architecture.jpg)





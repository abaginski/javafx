## Information about jar achives

#### richtextfx-0.7-M5-custom.jar
The java class archive *richtextfx-0.7-M5-custom.jar* consists of the base [richtextfx-0.7-M5.jar](https://github.com/TomasMikula/RichTextFX/releases) with a self-compiled version of `org.fxmisc.flowless.VirtualizedScrollPane`. The latest release of flowless called SNAPSHOT 0.6 does not have the annotations `@namedArgs` in the class `VirtualizedScrollPane` which are necessary to use that class in a fxml file. Please do only overwrite that file if you are confident, that the newer version includes those annotations.

###### Code example
```java
    public VirtualizedScrollPane(@NamedArg("content") V content) {
        [...]
}
```


###### Further links
- https://stackoverflow.com/questions/43695579/passing-objects-as-arguments-using-namedarg-annotation-in-javafx-8/43695630?noredirect=1#comment74438356_43695630
- https://stackoverflow.com/questions/26823157/what-is-the-purpose-of-namedarg-annotation-in-javafx-8/26824088#26824088

//
//  CodeBlockSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 11/04/2023.
//

import SwiftUI
import MarkdownUI


struct CodeBlockSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.codeLightTheme) private var lightTheme : String = AppColors.lightCodeTheme;
    @AppStorage(PreferencesManager.StoredPreferenceKey.codeDarkTheme) private var darkTheme : String = AppColors.darkCodeTheme;
    @State private var update : Bool = false;
    private let codeSample : String = """
```perl
sub shuffle {
  my @a = @_;
  foreach my $n (1 .. $#a) {
    my $k = int rand $n + 1;
    $k == $n or @a[$k, $n] = @a[$n, $k];
  }
  return @a;
}
```
""";
    @AppStorage(PreferencesManager.StoredPreferenceKey.hideLineNos) private var hideLineNos = false;
    @Environment(\.colorScheme) private var colorScheme;
    
    var body: some View {
        VStack (alignment: .leading){
            Toggle("Hide line numbers in code blocks", isOn: $hideLineNos).toggleStyle(.checkboxRight)
            Picker(selection: $lightTheme, label: Text("Light theme")) {
                ForEach(HighlightrSyntaxHighlighter.shared.availableThemes, id: \.self) { theme in
                    Text(theme).tag(theme)
                }
            } .onChange(of: lightTheme) { _ in
                HighlightrSyntaxHighlighter.shared.setTheme(theme: lightTheme, colorScheme: .light)
                update.toggle()
                PreferencesManager.shared.objectWillChange.send()
            }
            Markdown(codeSample).markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared).markdownBlockStyle(\.codeBlock) { config in
                config.label.padding([.leading, .trailing], 15).padding([.bottom], 15).padding([.top], 15)
            }.fixedSize(horizontal: false, vertical: true) .background(AppColors.chatBackgroundColor.environment(\.colorScheme, .light)).environment(\.colorScheme, .light) .id(update)
            Picker(selection: $darkTheme, label: Text("Dark theme")) {
                ForEach(HighlightrSyntaxHighlighter.shared.availableThemes, id: \.self) { theme in
                    Text(theme).tag(theme)
                }
            } .onChange(of: darkTheme) { _ in
                HighlightrSyntaxHighlighter.shared.setTheme(theme: darkTheme, colorScheme: .dark)
                update.toggle()
                PreferencesManager.shared.objectWillChange.send()
            }
            Markdown(codeSample).markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared).markdownBlockStyle(\.codeBlock) { config in
                config.label.padding([.leading, .trailing], 15).padding([.bottom], 15).padding([.top], 15)
            }.fixedSize(horizontal: false, vertical: true).background(AppColors.chatBackgroundColor.environment(\.colorScheme, .dark)).environment(\.colorScheme, .dark) .id(update)
        }
    }
}

//
//  CodeBlockSettings.swift
//  Machato
//
//  Created by Théophile Cailliau on 11/04/2023.
//

import SwiftUI
import MarkdownUI


struct CodeBlockSettings: View {
    @AppStorage(PreferencesManager.StoredPreferenceKey.code_light_theme) private var lightTheme : String = AppColors.lightCodeTheme;
    @AppStorage(PreferencesManager.StoredPreferenceKey.code_dark_theme) private var darkTheme : String = AppColors.darkCodeTheme;
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
    
    var body: some View {
        VStack{
            Picker(selection: $lightTheme, label: Text("Light theme")) {
                ForEach(HighlightrSyntaxHighlighter.shared.availableThemes, id: \.self) { theme in
                    Text(theme)
                }
            } .onChange(of: lightTheme) { _ in
                HighlightrSyntaxHighlighter.shared.setTheme(theme: lightTheme)
                update.toggle()
            }
            Markdown(codeSample).markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.shared).markdownBlockStyle(\.codeBlock) { config in
                config.label.padding([.leading, .trailing], 15).padding([.bottom], 15).padding([.top], 15)
            }.fixedSize(horizontal: false, vertical: true) .id(update)
            Picker(selection: $darkTheme, label: Text("Dark theme")) {
                ForEach(HighlightrSyntaxHighlighter.shared.availableThemes, id: \.self) { theme in
                    Text(theme)
                }
            } .onChange(of: darkTheme) { _ in
                HighlightrSyntaxHighlighter.darkShared.setTheme(theme: darkTheme)
                update.toggle()
            }
            Markdown(codeSample).markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter.darkShared).markdownBlockStyle(\.codeBlock) { config in
                config.label.padding([.leading, .trailing], 15).padding([.bottom], 15).padding([.top], 15)
            }.fixedSize(horizontal: false, vertical: true).background(AppColors.chatBackgroundColor.environment(\.colorScheme, .dark)) .id(update)
        }
    }
}

struct CodeBlockSettings_Previews: PreviewProvider {
    static var previews: some View {
        CodeBlockSettings()
    }
}

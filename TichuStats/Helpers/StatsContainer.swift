//
//  StatsContainer.swift
//  Tichu
//
//  Created by Leon on 24.04.2026.
//

import SwiftUI
import WidgetKit
//MARK: - StatsContainer used in StatsView
struct StatsContainer: View {

    
    @Environment(\.colorScheme) var colorScheme
    
    //MARK: Vars
    var title: String
    var description: String
    var image: String
    var counterLeft: Int
    var counterRight: Int
    var value: Double
    var percentage: Bool
    var inTop: Double
    var stat: Profile.playerStat
    var timeframe: Timeframe = .allTime
    //MARK: Computed Vars
    var items: [Profile]
    var digits: Int = 0
    
    //MARK: Width tracking (so minHeight can match width)
    @State private var containerWidth: CGFloat = 0
    
    //MARK: Body
    var body: some View {
        VStack(alignment:.leading){
            HStack{
                //For certain Image insteady of loading systeImage load custom Image
                /*if image == "exclamationmark.2.circle" || image == "bomb" || image == "exclamationmark.3.circle" {
                    Image(image)
                    .font(.system(size:16))
                    .frame(width: 20, height: 20)
                    .foregroundColor(.accentColor)
                    .redactedShimmer()
                }else{
                    Image(systemName:image)
                     .font(.system(size:16))
                    .foregroundColor(.accentColor)
                    .redactedShimmer()
                }*/
                Text(title)
                    .font(.system(size:20))
                    .fontWeight(.bold)
                    .redactedShimmer()
                Spacer()
                /*
                Image(systemName:"chevron.right.circle.fill").foregroundStyle(Color.gray)
                    .font(.system(size:14))*/
                
            }.padding(.bottom,6)
            
            VStack(alignment:.leading){
                ZStack{
                    if timeframe == .day{
                      
                        Text(String(localized: "statistics.timeframe.day"))
                    }else if timeframe == .week{
                        Text(String(localized: "statistics.timeframe.week"))
                    }else if timeframe == .month{
                        Text(String(localized: "statistics.timeframe.month"))
                    }else if timeframe == .year{
                        Text(String(localized: "statistics.timeframes.year"))
                    }else{
                        Text(String(localized: "statistics.timeframes.alltime"))
                    }
                }.animation(.easeInOut,value:timeframe).font(.system(size:14)).redactedShimmer()
                HStack{
                    if percentage == false {
                        if digits == 0{
                            Text("\(Int(value))").redactedShimmer()
                        }else{
                            Text(value, format: .number.precision(.fractionLength(digits))).fontWeight(.bold).redactedShimmer()
                        }
                      
                    }else{
             
                            Text("\(Int(value*100))%")
                        

                        
                            .fontWeight(.bold)
                        .redactedShimmer()
                    }
                    
                }.foregroundColor(.accentColor).font(.system(size:29/*,design:.rounded*/)).fontWeight(.bold)
            }
            /*Text(description)
                .font(.system(size:16))
                .multilineTextAlignment(.leading)
                .padding(.top,10)
                .padding(.horizontal,10)
                //.redactedShimmer()*/
            Spacer()
            if !items.isEmpty{
                Text(String(localized:"statistics.statscontainer.comparison")).font(.system(size:14)).padding(.bottom,-5).padding(.top,1).redactedShimmer()
                Divider()
            }else{
                Text(String(localized:"statistics.statscontainer.explanation")).font(.system(size:14)).padding(.bottom,-5).padding(.top,1).padding(.bottom,5).redactedShimmer()
                Text(description)
                    .font(.system(size:16))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                    
                    
                    .redactedShimmer()
            }
            
            //Automtically Load Dictionary and display it
            VStack(alignment: .leading, spacing: 8) {
                
                //For loop over all indices, id:value itssself,index is index
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let itemValue = item.getStat(for: stat,timeframe:timeframe)
                    VStack(spacing: 0) {
                        HStack {
                            if itemValue > value {
                                HStack{
                                    Image(systemName: "chevron.up.circle.fill")
                                        .foregroundStyle(.green)
                                        .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                        .font(.system(size: 14))
                                        .redactedShimmer()
                                    
                                    Text(item.name ?? "").font(.system(size:12))
                                        .font(.system(size: 14))
                                      
                                        .redactedShimmer()
                                }.lineLimit(.max)
                            } else if itemValue.isEqual(to: value) || itemValue == value {
                                Image(systemName: "equal.circle.fill")
                                    .foregroundStyle(.yellow)
                                    .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                    .font(.system(size: 14))
                                    .redactedShimmer()
                                Text(item.name ?? "")
                                    .font(.system(size: 14))
                                   
                                    .redactedShimmer()
                            } else {
                                Image(systemName: "chevron.down.circle.fill")
                                    .foregroundStyle(.red)
                                    .opacity(colorScheme == .dark ? 0.6 : 0.75)
                                    .font(.system(size:14))
                                    .redactedShimmer()
                                Text(item.name ?? "")
                                    .font(.system(size: 14))
                                    .redactedShimmer()
                            }
                            Spacer()
                            Text(percentage ? "\(Int(itemValue*100))%" : "\(Int(itemValue))")
                                .font(.system(size: 14))
                                .redactedShimmer()
                        }.padding(.bottom,3).padding(.top,-5)
                        if index != items.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .animation(.easeInOut, value: items)
        }
        .padding(10)
        .frame(maxHeight: .infinity)
        .frame(minHeight: max(containerWidth, 164), alignment: .topLeading)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { containerWidth = geo.size.width }
                    .onChange(of: geo.size.width) {
                        containerWidth = geo.size.width
                    }
            }
        )
        .containerBackground(.fill.tertiary, for: .widget)
        .background(colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white, in: .rect(cornerRadius: 24))
        /*.background(colorScheme == .dark ? Color(uiColor: .tertiarySystemFill) : .white, in: .rect(cornerRadius: 24))*/
    }
}



//MARK: - Sortby enum

    enum sortBy: String, CaseIterable {
        case valueUp
        case valueDown
        case nameUp
        case nameDown
    }
